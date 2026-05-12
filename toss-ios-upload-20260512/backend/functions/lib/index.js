import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onRequest } from "firebase-functions/v2/https";
import OpenAI from "openai";
initializeApp();
const db = getFirestore();
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
const model = process.env.OPENAI_MODEL || "gpt-5-mini";
const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
};
export const tossAI = onRequest({ secrets: ["OPENAI_API_KEY"], cors: true }, async (req, res) => {
    Object.entries(corsHeaders).forEach(([key, value]) => res.set(key, value));
    if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
    }
    if (req.method !== "POST") {
        res.status(405).json({ error: "Use POST." });
        return;
    }
    try {
        const body = req.body;
        if (body.mode === "analyze") {
            const result = await analyzeItem(body);
            if (body.uid && result.memoryUpdate) {
                await writeMemory(body.uid, result.memoryUpdate);
            }
            res.status(200).json(result);
            return;
        }
        if (body.mode === "chat") {
            const result = await chatWithToss(body);
            if (body.uid && result.memoryUpdate) {
                await writeMemory(body.uid, result.memoryUpdate);
            }
            res.status(200).json(result);
            return;
        }
        res.status(400).json({ error: "Unsupported mode." });
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ error: "Toss AI failed." });
    }
});
async function analyzeItem(input) {
    const response = await openai.responses.create({
        model,
        input: [
            {
                role: "system",
                content: [
                    {
                        type: "input_text",
                        text: "You are Toss, an enthusiastic decluttering assistant. Analyze one item photo. Reply shortly. Return only valid JSON matching the requested fields. Recommend exactly one of keep, donate, sell, toss. Give a realistic USD resale range.",
                    },
                ],
            },
            {
                role: "user",
                content: [
                    {
                        type: "input_text",
                        text: JSON.stringify({
                            note: input.note,
                            personality: input.context.personality,
                            memories: input.context.memories,
                            recentItems: input.context.recentItems,
                            requiredJsonFields: [
                                "reply",
                                "itemName",
                                "category",
                                "conditionGuess",
                                "recommendation",
                                "reason",
                                "sellEstimateLow",
                                "sellEstimateHigh",
                                "sellEstimateCurrency",
                                "memoryUpdate",
                            ],
                        }),
                    },
                    {
                        type: "input_image",
                        image_url: `data:image/jpeg;base64,${input.imageBase64}`,
                        detail: "low",
                    },
                ],
            },
        ],
    });
    return parseJson(response.output_text);
}
async function chatWithToss(input) {
    const response = await openai.responses.create({
        model,
        input: [
            {
                role: "system",
                content: [
                    {
                        type: "input_text",
                        text: "You are Toss, a short, enthusiastic decluttering assistant. Help the user decide what to keep, donate, sell, or toss. Return only JSON with reply and optional memoryUpdate.",
                    },
                ],
            },
            {
                role: "user",
                content: [
                    {
                        type: "input_text",
                        text: JSON.stringify({
                            message: input.text,
                            item: input.item?.analysis,
                            personality: input.context.personality,
                            memories: input.context.memories,
                            recentItems: input.context.recentItems,
                        }),
                    },
                ],
            },
        ],
    });
    return parseJson(response.output_text);
}
function parseJson(text) {
    const trimmed = text.trim().replace(/^```json\s*/i, "").replace(/```$/i, "");
    return JSON.parse(trimmed);
}
async function writeMemory(uid, text) {
    await db.collection("users").doc(uid).collection("memory").add({
        text,
        source: "tossAI",
        confidence: 0.7,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
    });
}
