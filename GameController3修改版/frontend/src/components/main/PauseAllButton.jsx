import { applyAction } from "../../api.js";

const PauseAllButton = ({ isPaused, legalPause, legalResume }) => {
  const action = isPaused 
    ? { type: "resume", args: null }
    : { type: "pause", args: null };
  
  const legal = isPaused ? legalResume : legalPause;
  const label = isPaused ? "▶️ 恢复 / RESUME" : "⏸️ 暂停 / PAUSE";
  const bgColor = isPaused 
    ? "bg-green-400 hover:bg-green-500 border-green-600"
    : "bg-yellow-400 hover:bg-yellow-500 border-yellow-600";
  const title = isPaused
    ? "恢复比赛，从暂停点继续 / Resume game from pause"
    : "暂停比赛（冻结所有状态）/ Pause game (freeze all states)";

  return (
    <button
      className={`w-full h-full px-4 py-3 rounded-lg border-2 font-bold text-lg ${
        legal
          ? `${bgColor} text-gray-900 shadow-lg hover:shadow-xl transition-all`
          : "text-gray-400 bg-gray-200 border-gray-400 cursor-not-allowed"
      }`}
      disabled={!legal}
      onClick={action ? () => applyAction(action) : () => {}}
      title={title}
    >
      {label}
    </button>
  );
};

export default PauseAllButton;
