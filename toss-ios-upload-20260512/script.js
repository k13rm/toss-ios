const stateKeys = {
  loggedIn: "tossMirror.loggedIn",
  surveyed: "tossMirror.surveyed",
  trial: "tossMirror.trial",
  theme: "tossMirror.theme",
  room: "tossMirror.room",
  goal: "tossMirror.goal",
  style: "tossMirror.style",
};

const surveySteps = [
  {
    key: "room",
    question: "Where should Toss help first?",
    options: [
      ["🛏", "Bedroom"],
      ["👕", "Closet"],
      ["🍳", "Kitchen"],
      ["📦", "Storage"],
      ["🏠", "Whole home"],
    ],
  },
  {
    key: "goal",
    question: "What is your main goal?",
    options: [
      ["⚡", "Make quick decisions"],
      ["🚚", "Prepare to move"],
      ["💸", "Sell more"],
      ["🎁", "Donate more"],
      ["🔎", "Find duplicates"],
    ],
  },
  {
    key: "style",
    question: "How direct should the AI be?",
    options: [
      ["🌤", "Gentle push"],
      ["🎯", "Be honest"],
      ["🧾", "Money minded"],
      ["🫧", "Space first"],
    ],
  },
];

const items = [
  {
    emoji: "👟",
    name: "Old running shoes",
    reason: "Worn soles, duplicate pair, low resale value.",
    score: 28,
    category: "Closet",
  },
  {
    emoji: "🔌",
    name: "Mystery cable",
    reason: "No matching device found. Low future-use confidence.",
    score: 12,
    category: "Drawer",
  },
  {
    emoji: "📚",
    name: "Expired manuals",
    reason: "Digital copies are easy to find. Paper stack can go.",
    score: 18,
    category: "Office",
  },
  {
    emoji: "🧥",
    name: "Winter jacket",
    reason: "Still useful, good condition, seasonal item.",
    score: 82,
    category: "Closet",
  },
  {
    emoji: "🎧",
    name: "Backup earbuds",
    reason: "Compact, working, and useful when your main pair dies.",
    score: 71,
    category: "Tech",
  },
];

const phrases = {
  toss: ["Tossed", "Space reclaimed", "Clutter cleared", "Gone from the pile"],
  keep: ["Kept", "Still earning its spot", "Keeper", "Saved with purpose"],
  donate: ["Donated", "Ready for a new home", "Passed along", "Good deed sorted"],
};

let surveyIndex = 0;
let itemIndex = 0;

const screens = document.querySelectorAll(".app-view");
const root = document.documentElement;
const surveyQuestion = document.querySelector("#survey-question");
const surveyOptions = document.querySelector("#survey-options");
const surveyStepLabel = document.querySelector("#survey-step-label");
const surveyProgress = document.querySelector("#survey-progress");
const surveyNext = document.querySelector("#survey-next");
const itemCard = document.querySelector("#item-card");
const itemEmoji = document.querySelector("#item-emoji");
const itemCategory = document.querySelector("#item-category");
const itemScore = document.querySelector("#item-score");
const itemName = document.querySelector("#item-name");
const itemReason = document.querySelector("#item-reason");
const toast = document.querySelector("#toast");
const settingsSheet = document.querySelector("#settings-sheet");
const dashboardSubtitle = document.querySelector("#dashboard-subtitle");

function getStored(key, fallback = "") {
  return localStorage.getItem(key) || fallback;
}

function setStored(key, value) {
  localStorage.setItem(key, value);
}

function has(key) {
  return localStorage.getItem(key) === "true";
}

function showScreen(name) {
  screens.forEach((screen) => {
    screen.classList.toggle("active", screen.dataset.screen === name);
  });
}

function route() {
  if (!has(stateKeys.loggedIn)) {
    showScreen("login");
  } else if (!has(stateKeys.surveyed)) {
    showScreen("survey");
    renderSurvey();
  } else if (!has(stateKeys.trial)) {
    showScreen("paywall");
  } else {
    showScreen("dashboard");
    renderDashboardContext();
    renderItem();
  }
}

function applyTheme(theme) {
  const actualTheme = theme === "system"
    ? (window.matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark")
    : theme;

  root.dataset.theme = actualTheme;
  setStored(stateKeys.theme, theme);

  document.querySelectorAll(".theme-option").forEach((button) => {
    button.classList.toggle("active", button.dataset.theme === theme);
  });
}

function signIn() {
  setStored(stateKeys.loggedIn, "true");
  route();
}

function selectedForStep(step) {
  const key = stateKeys[step.key];
  return getStored(key, step.options[0][1]);
}

function renderSurvey() {
  const step = surveySteps[surveyIndex];
  surveyStepLabel.textContent = `Step ${surveyIndex + 1} of ${surveySteps.length}`;
  surveyQuestion.textContent = step.question;
  surveyProgress.style.width = `${((surveyIndex + 1) / surveySteps.length) * 100}%`;
  surveyOptions.innerHTML = "";

  const selected = selectedForStep(step);

  step.options.forEach(([emoji, label]) => {
    const option = document.createElement("button");
    option.className = "survey-option";
    option.type = "button";
    option.innerHTML = `<span>${emoji}</span><span>${label}</span><b>${selected === label ? "✓" : ""}</b>`;
    option.classList.toggle("selected", selected === label);
    option.addEventListener("click", () => {
      setStored(stateKeys[step.key], label);
      renderSurvey();
    });
    surveyOptions.appendChild(option);
  });

  surveyNext.querySelector("span:first-child").textContent = surveyIndex === surveySteps.length - 1 ? "See plans" : "Next";
}

function nextSurveyStep() {
  if (surveyIndex < surveySteps.length - 1) {
    surveyIndex += 1;
    renderSurvey();
    return;
  }

  setStored(stateKeys.surveyed, "true");
  route();
}

function renderDashboardContext() {
  const room = getStored(stateKeys.room, "Bedroom");
  const style = getStored(stateKeys.style, "Gentle push");
  dashboardSubtitle.textContent = `${room} · ${style}`;
}

function renderItem() {
  const item = items[itemIndex % items.length];
  itemEmoji.textContent = item.emoji;
  itemCategory.textContent = item.category;
  itemScore.textContent = `${item.score}% keep`;
  itemName.textContent = item.name;
  itemReason.textContent = item.reason;
}

function randomPhrase(action) {
  const list = phrases[action];
  return list[Math.floor(Math.random() * list.length)];
}

function showToast(message) {
  toast.textContent = message;
  toast.classList.add("show");
  window.clearTimeout(showToast.timeout);
  showToast.timeout = window.setTimeout(() => toast.classList.remove("show"), 1600);
}

function decide(action) {
  const item = items[itemIndex % items.length];
  const animation = action === "toss" ? "tossing" : action === "keep" ? "keeping" : "donating";
  itemCard.classList.remove("tossing", "keeping", "donating");
  void itemCard.offsetWidth;
  itemCard.classList.add(animation);
  showToast(`${randomPhrase(action)} ${item.emoji}`);

  window.setTimeout(() => {
    itemIndex += 1;
    renderItem();
    itemCard.classList.remove("tossing", "keeping", "donating");
    itemCard.animate(
      [
        { opacity: 0, transform: "translateY(14px) scale(0.98)" },
        { opacity: 1, transform: "translateY(0) scale(1)" },
      ],
      { duration: 260, easing: "ease-out" }
    );
  }, action === "toss" ? 470 : 420);
}

function selectTab(tabName) {
  document.querySelectorAll(".segment").forEach((tab) => {
    tab.classList.toggle("active", tab.dataset.tab === tabName);
  });
  document.querySelectorAll(".tab-panel").forEach((panel) => {
    panel.classList.toggle("active", panel.dataset.panel === tabName);
  });
}

function openSettings() {
  settingsSheet.classList.add("open");
  settingsSheet.setAttribute("aria-hidden", "false");
}

function closeSettings() {
  settingsSheet.classList.remove("open");
  settingsSheet.setAttribute("aria-hidden", "true");
}

function resetDemo() {
  Object.values(stateKeys).forEach((key) => localStorage.removeItem(key));
  surveyIndex = 0;
  itemIndex = 0;
  applyTheme("dark");
  closeSettings();
  route();
}

document.querySelectorAll("[data-auth]").forEach((button) => {
  button.addEventListener("click", signIn);
});

document.querySelector("#demo-login").addEventListener("click", signIn);
surveyNext.addEventListener("click", nextSurveyStep);

document.querySelectorAll(".plan").forEach((plan) => {
  plan.addEventListener("click", () => {
    document.querySelectorAll(".plan").forEach((item) => item.classList.remove("selected"));
    plan.classList.add("selected");
  });
});

document.querySelector("#start-trial").addEventListener("click", () => {
  setStored(stateKeys.trial, "true");
  route();
  showToast("Trial started 💎");
});

document.querySelectorAll(".decision").forEach((button) => {
  button.addEventListener("click", () => decide(button.dataset.action));
});

document.querySelectorAll(".segment").forEach((button) => {
  button.addEventListener("click", () => selectTab(button.dataset.tab));
});

document.querySelector("#scan-button").addEventListener("click", () => {
  selectTab("decide");
  showToast("Scan sorted 📸");
});

document.querySelector("#settings-open").addEventListener("click", openSettings);
document.querySelector("#settings-close").addEventListener("click", closeSettings);
document.querySelector("#settings-close-area").addEventListener("click", closeSettings);
document.querySelector("#reset-demo").addEventListener("click", resetDemo);

document.querySelectorAll(".theme-option").forEach((button) => {
  button.addEventListener("click", () => applyTheme(button.dataset.theme));
});

window.matchMedia("(prefers-color-scheme: light)").addEventListener("change", () => {
  if (getStored(stateKeys.theme, "dark") === "system") {
    applyTheme("system");
  }
});

applyTheme(getStored(stateKeys.theme, "dark"));
route();
