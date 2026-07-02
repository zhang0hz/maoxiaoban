const demoSteps = [
  {
    section: "hero",
    label: "开场",
    duration: 20000,
    flowStep: 0,
    reminderAction: null
  },
  {
    section: "work",
    label: "工作低打扰",
    duration: 35000,
    flowStep: 1,
    reminderAction: null
  },
  {
    section: "leisure",
    label: "休闲动作资产",
    duration: 30000,
    flowStep: 2,
    reminderAction: null
  },
  {
    section: "reminders",
    label: "提醒反馈",
    duration: 30000,
    flowStep: 2,
    reminderAction: "later"
  },
  {
    section: "signals",
    label: "桌面信号流程",
    duration: 30000,
    flowStep: 0,
    reminderAction: null
  },
  {
    section: "privacy",
    label: "隐私边界",
    duration: 10000,
    flowStep: 3,
    reminderAction: "skip"
  },
  {
    section: "investor",
    label: "投资亮点",
    duration: 25000,
    flowStep: 3,
    reminderAction: "done"
  }
];

const reminderMessages = {
  done: "当前状态：已完成，小猫正在庆祝",
  later: "当前状态：已延后 15 分钟，保持低打扰",
  skip: "当前状态：本次已跳过，不再重复打扰"
};

const petImages = {
  default: "assets/miu-peek.gif",
  done: "assets/miu-celebrate.gif"
};

let currentStepIndex = 0;
let demoTimer = null;
let flowTimer = null;
let isPlaying = false;
let isPaused = false;
let isComplete = false;

function getStepElement(step) {
  return document.querySelector(`[data-section="${step.section}"]`);
}

function updateProgress() {
  const progress = document.getElementById("demoProgress");
  if (!progress) {
    return;
  }

  const step = demoSteps[currentStepIndex];
  const playbackState = isComplete ? "演示完成" : isPlaying ? (isPaused ? "已暂停" : "录屏中") : "演示未开始";
  progress.textContent = `${playbackState} · ${currentStepIndex + 1}/${demoSteps.length} ${step.label}`;
}

function syncPauseButton() {
  const pauseButton = document.getElementById("pauseDemo");
  if (pauseButton) {
    pauseButton.textContent = isPaused ? "继续" : "暂停";
  }
}

function clearDemoTimer() {
  if (demoTimer) {
    window.clearTimeout(demoTimer);
    demoTimer = null;
  }
}

function clearFlowTimer() {
  if (flowTimer) {
    window.clearInterval(flowTimer);
    flowTimer = null;
  }
}

function scheduleNextStep() {
  clearDemoTimer();

  if (!isPlaying || isPaused) {
    return;
  }

  if (currentStepIndex >= demoSteps.length - 1) {
    demoTimer = window.setTimeout(finishDemo, demoSteps[currentStepIndex].duration);
    return;
  }

  demoTimer = window.setTimeout(() => {
    showStep(currentStepIndex + 1);
  }, demoSteps[currentStepIndex].duration);
}

function startFlowPlayback(startAt = 0) {
  clearFlowTimer();
  let activeFlowStep = startAt;
  setFlowStep(activeFlowStep);

  flowTimer = window.setInterval(() => {
    activeFlowStep = (activeFlowStep + 1) % 4;
    setFlowStep(activeFlowStep);
  }, 1400);
}

function startDemo() {
  isPlaying = true;
  isPaused = false;
  isComplete = false;
  document.body.classList.add("recording-active");
  document.body.classList.remove("recording-complete");
  syncPauseButton();
  showStep(0);
}

function finishDemo() {
  clearDemoTimer();
  clearFlowTimer();
  isPlaying = false;
  isPaused = false;
  isComplete = true;
  document.body.classList.add("recording-complete");
  syncPauseButton();
  updateProgress();
}

function showStep(nextIndex) {
  const boundedIndex = Math.max(0, Math.min(nextIndex, demoSteps.length - 1));
  currentStepIndex = boundedIndex;

  document.querySelectorAll("[data-demo-step]").forEach((section) => {
    section.classList.toggle("active-step", section.dataset.demoStep === String(boundedIndex));
  });

  const step = demoSteps[boundedIndex];
  const stepElement = getStepElement(step);
  if (stepElement) {
    stepElement.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  if (step.section === "signals") {
    if (isPlaying && !isPaused) {
      startFlowPlayback(step.flowStep);
    } else {
      clearFlowTimer();
      setFlowStep(step.flowStep);
    }
  } else {
    clearFlowTimer();
    setFlowStep(step.flowStep);
  }

  if (step.reminderAction) {
    handleReminderAction(step.reminderAction);
  }

  updateProgress();
  scheduleNextStep();
}

function handleReminderAction(action) {
  const bubble = document.getElementById("reminderBubble");
  const status = document.getElementById("reminderStatus");
  const reminderPet = document.querySelector(".reminder-pet");

  if (!reminderMessages[action] || !bubble || !status) {
    return;
  }

  bubble.dataset.state = action;
  status.textContent = reminderMessages[action];

  document.querySelectorAll("[data-reminder-action]").forEach((button) => {
    button.setAttribute("aria-pressed", String(button.dataset.reminderAction === action));
  });

  if (reminderPet) {
    reminderPet.src = action === "done" ? petImages.done : petImages.default;
    reminderPet.alt = action === "done" ? "猫小伴完成提醒后庆祝" : "猫小伴提醒前探头";
  }
}

function setFlowStep(stepIndex) {
  document.querySelectorAll("[data-flow-step]").forEach((item) => {
    item.classList.toggle("active", item.dataset.flowStep === String(stepIndex));
  });
}

function togglePause() {
  if (!isPlaying) {
    startDemo();
    return;
  }

  isPaused = !isPaused;
  syncPauseButton();

  if (isPaused) {
    clearDemoTimer();
    clearFlowTimer();
  } else {
    const step = demoSteps[currentStepIndex];
    if (step.section === "signals") {
      startFlowPlayback(step.flowStep);
    }
    scheduleNextStep();
  }

  updateProgress();
}

function moveStep(offset) {
  if (!isPlaying) {
    isPlaying = true;
    isPaused = false;
    isComplete = false;
    document.body.classList.add("recording-active");
    document.body.classList.remove("recording-complete");
    syncPauseButton();
  }

  showStep(currentStepIndex + offset);
}

document.addEventListener("DOMContentLoaded", () => {
  const startButton = document.getElementById("startDemo");
  const pauseButton = document.getElementById("pauseDemo");
  const nextButton = document.getElementById("nextStep");
  const prevButton = document.getElementById("prevStep");

  startButton?.addEventListener("click", startDemo);
  pauseButton?.addEventListener("click", togglePause);
  nextButton?.addEventListener("click", () => moveStep(1));
  prevButton?.addEventListener("click", () => moveStep(-1));

  document.querySelectorAll("[data-reminder-action]").forEach((button) => {
    button.addEventListener("click", () => {
      handleReminderAction(button.dataset.reminderAction);
    });
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "ArrowRight") {
      event.preventDefault();
      moveStep(1);
    }

    if (event.key === "ArrowLeft") {
      event.preventDefault();
      moveStep(-1);
    }

    if (event.key === " ") {
      event.preventDefault();
      togglePause();
    }
  });

  setFlowStep(0);
  updateProgress();
});
