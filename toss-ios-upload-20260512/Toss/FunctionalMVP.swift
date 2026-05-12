import AVFoundation
import PhotosUI
import Speech
import SwiftUI
import UIKit

enum TossConfig {
    static let aiFunctionURL = ""
}

enum SortDecision: String, Codable, CaseIterable, Identifiable {
    case keep
    case donate
    case sell
    case toss

    var id: String { rawValue }

    var label: String {
        switch self {
        case .keep: "Keep"
        case .donate: "Donate"
        case .sell: "Sell"
        case .toss: "Toss"
        }
    }

    var emoji: String {
        switch self {
        case .keep: "💚"
        case .donate: "🎁"
        case .sell: "💸"
        case .toss: "🗑️"
        }
    }

    var color: Color {
        switch self {
        case .keep: .teal
        case .donate: .orange
        case .sell: .blue
        case .toss: .red
        }
    }
}

enum TossPersonality: String, Codable, CaseIterable, Identifiable {
    case gentle = "Gentle Push"
    case honest = "Brutally Honest"
    case money = "Money Minded"
    case minimalist = "Minimalist Coach"

    var id: String { rawValue }

    var promptHint: String {
        switch self {
        case .gentle: "encouraging, short, and kind"
        case .honest: "direct, short, and practical"
        case .money: "focused on resale value and opportunity cost"
        case .minimalist: "focused on space, low friction, and fewer possessions"
        }
    }
}

struct ItemAnalysis: Codable, Equatable {
    var reply: String
    var itemName: String
    var category: String
    var conditionGuess: String
    var recommendation: SortDecision
    var reason: String
    var sellEstimateLow: Int
    var sellEstimateHigh: Int
    var sellEstimateCurrency: String
    var memoryUpdate: String?

    static let empty = ItemAnalysis(
        reply: "Take a photo and I’ll help you decide.",
        itemName: "Unsorted item",
        category: "Unknown",
        conditionGuess: "Unknown",
        recommendation: .donate,
        reason: "No analysis yet.",
        sellEstimateLow: 0,
        sellEstimateHigh: 0,
        sellEstimateCurrency: "USD",
        memoryUpdate: nil
    )
}

struct TossInventoryItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var createdAt = Date()
    var photoFilename: String?
    var userNote: String
    var analysis: ItemAnalysis
    var decision: SortDecision?
}

struct TossChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    var createdAt = Date()
    var role: String
    var text: String
    var itemID: UUID?
}

struct TossMemory: Identifiable, Codable, Equatable {
    var id = UUID()
    var createdAt = Date()
    var text: String
}

struct TossSnapshot: Codable {
    var items: [TossInventoryItem] = []
    var messages: [TossChatMessage] = []
    var memories: [TossMemory] = []
    var personality: TossPersonality = .gentle
}

@MainActor
final class TossMVPStore: ObservableObject {
    @Published var items: [TossInventoryItem] = []
    @Published var messages: [TossChatMessage] = []
    @Published var memories: [TossMemory] = []
    @Published var personality: TossPersonality = .gentle {
        didSet {
            guard oldValue != personality else { return }
            save()
        }
    }
    @Published var isAnalyzing = false
    @Published var activeError: String?

    private let aiService = TossAIService()
    private let storeURL: URL
    private let imageDirectory: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        storeURL = documents.appendingPathComponent("toss-mvp-store.json")
        imageDirectory = documents.appendingPathComponent("TossItemPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
        load()
    }

    var currentItem: TossInventoryItem? { items.first(where: { $0.decision == nil }) ?? items.first }

    var sortedCount: Int { items.filter { $0.decision != nil }.count }

    var estimatedRevenue: Int {
        items
            .filter { $0.decision == .sell || $0.analysis.recommendation == .sell }
            .reduce(0) { $0 + (($1.analysis.sellEstimateLow + $1.analysis.sellEstimateHigh) / 2) }
    }

    func addPhotoForAnalysis(_ data: Data, note: String) async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            let filename = "\(UUID().uuidString).jpg"
            let url = imageDirectory.appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)

            let context = TossAIContext(
                personality: personality,
                memories: memories.map(\.text),
                recentItems: items.prefix(6).map { $0.analysis.itemName }
            )
            let analysis = try await aiService.analyzePhoto(imageData: data, note: note, context: context)
            let item = TossInventoryItem(photoFilename: filename, userNote: note, analysis: analysis)
            items.insert(item, at: 0)

            messages.append(TossChatMessage(role: "assistant", text: analysis.reply, itemID: item.id))
            if let memory = analysis.memoryUpdate, !memory.isEmpty {
                memories.insert(TossMemory(text: memory), at: 0)
            }
            save()
        } catch {
            activeError = "I couldn't analyze that photo yet. Try again in a moment."
        }
    }

    func sendChat(_ text: String, attachedItem: TossInventoryItem?) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let itemID = attachedItem?.id
        messages.append(TossChatMessage(role: "user", text: text, itemID: itemID))
        save()

        do {
            let context = TossAIContext(
                personality: personality,
                memories: memories.map(\.text),
                recentItems: items.prefix(6).map { $0.analysis.itemName }
            )
            let response = try await aiService.chat(text: text, item: attachedItem, context: context)
            messages.append(TossChatMessage(role: "assistant", text: response.reply, itemID: itemID))
            if let memory = response.memoryUpdate, !memory.isEmpty {
                memories.insert(TossMemory(text: memory), at: 0)
            }
            save()
        } catch {
            activeError = "I couldn't answer right now, but your message is saved."
        }
    }

    func decide(_ decision: SortDecision, for item: TossInventoryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].decision = decision
        let message = "\(decision.emoji) \(decision.label): \(item.analysis.itemName)"
        messages.append(TossChatMessage(role: "assistant", text: message, itemID: item.id))
        save()
    }

    func image(for item: TossInventoryItem) -> UIImage? {
        guard let filename = item.photoFilename else { return nil }
        return UIImage(contentsOfFile: imageDirectory.appendingPathComponent(filename).path)
    }

    func resetLocalData() {
        items = []
        messages = []
        memories = []
        personality = .gentle
        try? FileManager.default.removeItem(at: storeURL)
        save()
    }

    private func load() {
        guard
            let data = try? Data(contentsOf: storeURL),
            let snapshot = try? JSONDecoder.toss.decode(TossSnapshot.self, from: data)
        else { return }

        items = snapshot.items
        messages = snapshot.messages
        memories = snapshot.memories
        personality = snapshot.personality
    }

    private func save() {
        let snapshot = TossSnapshot(items: items, messages: messages, memories: memories, personality: personality)
        guard let data = try? JSONEncoder.toss.encode(snapshot) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }
}

struct TossAIContext: Codable {
    var personality: TossPersonality
    var memories: [String]
    var recentItems: [String]
}

struct TossAIChatResponse: Codable {
    var reply: String
    var memoryUpdate: String?
}

final class TossAIService {
    func analyzePhoto(imageData: Data, note: String, context: TossAIContext) async throws -> ItemAnalysis {
        if let url = URL(string: TossConfig.aiFunctionURL), !TossConfig.aiFunctionURL.isEmpty {
            return try await callAnalyzeEndpoint(url: url, imageData: imageData, note: note, context: context)
        }

        try await Task.sleep(nanoseconds: 700_000_000)
        return localAnalysis(note: note, context: context)
    }

    func chat(text: String, item: TossInventoryItem?, context: TossAIContext) async throws -> TossAIChatResponse {
        if let url = URL(string: TossConfig.aiFunctionURL), !TossConfig.aiFunctionURL.isEmpty {
            return try await callChatEndpoint(url: url, text: text, item: item, context: context)
        }

        try await Task.sleep(nanoseconds: 450_000_000)
        let itemName = item?.analysis.itemName ?? "this item"
        let decision = item?.analysis.recommendation ?? .donate
        let reply = "I’d \(decision.label.lowercased()) \(itemName). Quick win: \(item?.analysis.reason ?? "it doesn’t need a long debate.")"
        return TossAIChatResponse(reply: reply, memoryUpdate: "User asks for reassurance before sorting uncertain items.")
    }

    private func callAnalyzeEndpoint(url: URL, imageData: Data, note: String, context: TossAIContext) async throws -> ItemAnalysis {
        struct Request: Codable {
            var mode: String
            var imageBase64: String
            var note: String
            var context: TossAIContext
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.toss.encode(Request(mode: "analyze", imageBase64: imageData.base64EncodedString(), note: note, context: context))
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder.toss.decode(ItemAnalysis.self, from: data)
    }

    private func callChatEndpoint(url: URL, text: String, item: TossInventoryItem?, context: TossAIContext) async throws -> TossAIChatResponse {
        struct Request: Codable {
            var mode: String
            var text: String
            var item: TossInventoryItem?
            var context: TossAIContext
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.toss.encode(Request(mode: "chat", text: text, item: item, context: context))
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder.toss.decode(TossAIChatResponse.self, from: data)
    }

    private func localAnalysis(note: String, context: TossAIContext) -> ItemAnalysis {
        let lower = note.lowercased()
        let itemName: String
        let category: String
        let recommendation: SortDecision
        let low: Int
        let high: Int

        if lower.contains("shoe") || lower.contains("sneaker") {
            itemName = "Running shoes"
            category = "Closet"
            recommendation = .donate
            low = 8
            high = 22
        } else if lower.contains("cable") || lower.contains("charger") {
            itemName = "Loose cable"
            category = "Tech"
            recommendation = .toss
            low = 0
            high = 5
        } else if lower.contains("jacket") || lower.contains("coat") {
            itemName = "Jacket"
            category = "Closet"
            recommendation = .sell
            low = 18
            high = 45
        } else {
            itemName = note.isEmpty ? "Photo item" : String(note.prefix(36))
            category = "Home"
            recommendation = context.personality == .money ? .sell : .donate
            low = 10
            high = 30
        }

        return ItemAnalysis(
            reply: "Nice, I’ve got this. I’d \(recommendation.label.lowercased()) it and move on \(recommendation.emoji)",
            itemName: itemName,
            category: category,
            conditionGuess: "Usable",
            recommendation: recommendation,
            reason: "It looks like a low-friction decision, and your \(context.personality.rawValue.lowercased()) mode points toward \(recommendation.label.lowercased()).",
            sellEstimateLow: low,
            sellEstimateHigh: high,
            sellEstimateCurrency: "USD",
            memoryUpdate: "User is sorting \(category.lowercased()) items with \(context.personality.rawValue) personality."
        )
    }
}

extension JSONEncoder {
    static var toss: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var toss: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

struct FunctionalDashboardView: View {
    @StateObject private var store = TossMVPStore()

    var body: some View {
        TabView {
            TossHomeView(store: store)
                .tabItem { Label("Home", systemImage: "house.fill") }
            TossCameraView(store: store)
                .tabItem { Label("Camera", systemImage: "camera.fill") }
            TossChatView(store: store)
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
            TossMemoryView(store: store)
                .tabItem { Label("Memory", systemImage: "person.crop.circle.fill") }
        }
        .tint(.teal)
        .alert("Toss needs a moment", isPresented: Binding(get: { store.activeError != nil }, set: { if !$0 { store.activeError = nil } })) {
            Button("OK", role: .cancel) { store.activeError = nil }
        } message: {
            Text(store.activeError ?? "")
        }
    }
}

struct TossHomeView: View {
    @ObservedObject var store: TossMVPStore

    var body: some View {
        NavigationStack {
            ZStack {
                TossBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        if store.items.isEmpty {
                            emptyState
                        } else {
                            summary
                            ForEach(store.items) { item in
                                TossAnalyzedItemCard(store: store, item: item)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Toss")
                .font(.system(size: 40, weight: .black, design: .rounded))
            Text("AI sorting that remembers what matters to you.")
                .foregroundStyle(.secondary)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 18)
    }

    private var emptyState: some View {
        GlassPanel(cornerRadius: 34, tint: .white.opacity(0.08)) {
            VStack(spacing: 16) {
                Text("📸")
                    .font(.system(size: 76))
                Text("Take photos of your stuff, decide what to sort out")
                    .font(.title2.weight(.black))
                    .multilineTextAlignment(.center)
                Text("Start with one item. Toss will judge it, estimate sell value, and help you keep, donate, sell, or throw away.")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    private var summary: some View {
        HStack(spacing: 10) {
            TossMetric(label: "Items", value: "\(store.items.count)", emoji: "📦")
            TossMetric(label: "Sorted", value: "\(store.sortedCount)", emoji: "🪄")
            TossMetric(label: "Sell est.", value: "$\(store.estimatedRevenue)", emoji: "💸")
        }
    }
}

struct TossMetric: View {
    let label: String
    let value: String
    let emoji: String

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
            Text(value).font(.title3.weight(.black))
            Text(label).font(.caption.weight(.bold)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .liquidGlass(cornerRadius: 22, tint: .white.opacity(0.06))
    }
}

struct TossAnalyzedItemCard: View {
    @ObservedObject var store: TossMVPStore
    let item: TossInventoryItem

    var body: some View {
        GlassPanel(cornerRadius: 30, tint: .white.opacity(0.08)) {
            VStack(alignment: .leading, spacing: 14) {
                if let image = store.image(for: item) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 210)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.analysis.category.uppercased())
                            .font(.caption.weight(.black))
                            .foregroundStyle(.teal)
                        Spacer()
                        Text("$\(item.analysis.sellEstimateLow)-$\(item.analysis.sellEstimateHigh)")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.secondary)
                    }
                    Text(item.analysis.itemName)
                        .font(.title2.weight(.black))
                    Text(item.analysis.reply)
                        .font(.callout.weight(.semibold))
                    Text(item.analysis.reason)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    ForEach(SortDecision.allCases) { decision in
                        Button {
                            store.decide(decision, for: item)
                        } label: {
                            VStack(spacing: 3) {
                                Text(decision.emoji)
                                Text(decision.label)
                                    .font(.caption2.weight(.black))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white)
                        .background(decision.color.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }

                if let decision = item.decision {
                    Text("Sorted as \(decision.emoji) \(decision.label)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(decision.color)
                }
            }
        }
    }
}

struct TossCameraView: View {
    @ObservedObject var store: TossMVPStore
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var note = ""
    @State private var showingCamera = false

    var body: some View {
        NavigationStack {
            ZStack {
                TossBackground()
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add an item")
                            .font(.largeTitle.weight(.black))
                        Text("Take one photo, add a hint, and let Toss judge it.")
                            .foregroundStyle(.secondary)
                            .font(.callout.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("Example: old shoes, maybe donate?", text: $note, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding()
                        .liquidGlass(cornerRadius: 22, tint: .white.opacity(0.08))

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose photo", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)

                    Button {
                        showingCamera = true
                    } label: {
                        Label("Take photo", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    if store.isAnalyzing {
                        ProgressView("Analyzing with Toss AI...")
                            .font(.headline)
                            .padding()
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCamera) {
                TossCameraPicker { data in
                    Task { await store.addPhotoForAnalysis(data, note: note) }
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await store.addPhotoForAnalysis(data, note: note)
                    }
                }
            }
        }
    }
}

struct TossChatView: View {
    @ObservedObject var store: TossMVPStore
    @StateObject private var speech = TossSpeechController()
    @State private var text = ""

    var body: some View {
        NavigationStack {
            ZStack {
                TossBackground()
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Ask Toss")
                                .font(.largeTitle.weight(.black))
                            Text("Attach the current item and talk it out.")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(store.messages) { message in
                                TossMessageBubble(message: message)
                            }
                        }
                    }

                    VStack(spacing: 8) {
                        if let item = store.currentItem {
                            Text("Attached: \(item.analysis.itemName)")
                                .font(.caption.weight(.black))
                                .foregroundStyle(.teal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        HStack(spacing: 8) {
                            TextField("Ask if you should keep, donate, sell...", text: $text, axis: .vertical)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .liquidGlass(cornerRadius: 18, tint: .white.opacity(0.08))

                            Button {
                                Task {
                                    if speech.isRecording {
                                        text = speech.stop()
                                    } else {
                                        await speech.start()
                                    }
                                }
                            } label: {
                                Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                                    .frame(width: 46, height: 46)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(speech.isRecording ? .red : .teal)

                            Button {
                                let outgoing = text
                                text = ""
                                Task { await store.sendChat(outgoing, attachedItem: store.currentItem) }
                            } label: {
                                Image(systemName: "arrow.up")
                                    .frame(width: 46, height: 46)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                    }
                }
                .padding(20)
            }
            .navigationBarHidden(true)
        }
    }
}

struct TossMessageBubble: View {
    let message: TossChatMessage

    var body: some View {
        HStack {
            if message.role == "user" { Spacer() }
            Text(message.text)
                .font(.callout.weight(.semibold))
                .padding(12)
                .foregroundStyle(message.role == "user" ? .white : .primary)
                .background(message.role == "user" ? Color.teal.gradient : Color.clear.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .liquidGlass(cornerRadius: 18, tint: message.role == "user" ? .teal.opacity(0.1) : .white.opacity(0.08))
            if message.role != "user" { Spacer() }
        }
    }
}

struct TossMemoryView: View {
    @ObservedObject var store: TossMVPStore

    var body: some View {
        NavigationStack {
            ZStack {
                TossBackground()
                List {
                    Section("AI personality") {
                        Picker("Personality", selection: $store.personality) {
                            ForEach(TossPersonality.allCases) { personality in
                                Text(personality.rawValue).tag(personality)
                            }
                        }
                    }

                    Section("Memory") {
                        if store.memories.isEmpty {
                            Text("Toss will remember your sorting preferences as you chat and decide.")
                        } else {
                            ForEach(store.memories) { memory in
                                Text(memory.text)
                            }
                        }
                    }

                    Section("Local MVP") {
                        Button("Reset item, chat, and memory data", role: .destructive) {
                            store.resetLocalData()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Memory")
        }
    }
}

struct TossCameraPicker: UIViewControllerRepresentable {
    var onImageData: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: TossCameraPicker

        init(parent: TossCameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.82) {
                parent.onImageData(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

@MainActor
final class TossSpeechController: ObservableObject {
    @Published var isRecording = false
    private let recognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var transcript = ""

    func start() async {
        let authorized = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard authorized else { return }

        transcript = ""
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        task = recognizer?.recognitionTask(with: request) { [weak self] result, _ in
            guard let self, let result else { return }
            Task { @MainActor in
                self.transcript = result.bestTranscription.formattedString
            }
        }

        try? AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        try? audioEngine.start()
        isRecording = true
    }

    func stop() -> String {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isRecording = false
        return transcript
    }
}
