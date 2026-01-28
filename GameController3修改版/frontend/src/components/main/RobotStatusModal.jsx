import { XMarkIcon } from "@heroicons/react/24/outline";
import { formatMMSS } from "../../utils.js";

const connectionStatusInfo = {
  0: { label: "Offline", color: "text-red-600", bgColor: "bg-red-100" },
  1: { label: "Bad", color: "text-yellow-600", bgColor: "bg-yellow-100" },
  2: { label: "Good", color: "text-green-600", bgColor: "bg-green-100" },
};

const penaltyDescriptions = {
  noPenalty: "No Penalty",
  substitute: "Substitute",
  pickedUp: "Picked Up",
  illegalPositionInSet: "Illegal Position in Set",
  illegalPosition: "Illegal Position",
  motionInStandby: "Motion in Standby",
  motionInSet: "Motion in Set",
  fallenInactive: "Fallen / Inactive",
  localGameStuck: "Local Game Stuck",
  ballHolding: "Ball Holding",
  playerStance: "Player Stance",
  playerPushing: "Pushing",
  playingWithArmsHands: "Playing with Arms/Hands",
  leavingTheField: "Leaving the Field",
};

const RobotStatusModal = ({ player, side, teamParams, teamName, onClose }) => {
  const connectionInfo = connectionStatusInfo[player.connectionStatus] || connectionStatusInfo[0];
  const isGoalkeeper = player.number === teamParams.goalkeeper;
  const jerseyColor = isGoalkeeper ? teamParams.goalkeeperColor : teamParams.fieldPlayerColor;

  // 处理 ESC 键关闭
  const handleKeyDown = (e) => {
    if (e.key === "Escape") {
      onClose();
    }
  };

  // 点击遮罩层关闭
  const handleBackdropClick = (e) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      onClick={handleBackdropClick}
      onKeyDown={handleKeyDown}
      tabIndex={-1}
    >
      <div className="bg-white rounded-lg shadow-xl p-6 w-96 max-w-full mx-4 animate-fade-in">
        {/* Header */}
        <div className="flex items-center justify-between mb-4 border-b pb-3">
          <h2 className="text-xl font-bold">
            Robot #{player.number} - {teamName}
          </h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700 transition-colors"
            aria-label="Close"
          >
            <XMarkIcon className="w-6 h-6" />
          </button>
        </div>

        {/* Content */}
        <div className="space-y-4">
          {/* Connection Status */}
          <div className="flex items-center justify-between p-3 rounded-md bg-gray-50">
            <span className="font-semibold text-gray-700">Connection Status:</span>
            <div className="flex items-center gap-2">
              <span className={`w-3 h-3 rounded-full ${connectionInfo.bgColor}`}>
                <span className={`block w-full h-full rounded-full ${connectionInfo.color}`} />
              </span>
              <span className={`font-bold ${connectionInfo.color}`}>
                {connectionInfo.label}
              </span>
            </div>
          </div>

          {/* Team Side */}
          <div className="flex items-center justify-between p-3 rounded-md bg-gray-50">
            <span className="font-semibold text-gray-700">Team Side:</span>
            <span className="font-medium capitalize">{side}</span>
          </div>

          {/* Jersey Info */}
          <div className="flex items-center justify-between p-3 rounded-md bg-gray-50">
            <span className="font-semibold text-gray-700">Jersey:</span>
            <span className="font-medium capitalize">
              {jerseyColor} {isGoalkeeper ? "(Goalkeeper)" : "(Field Player)"}
            </span>
          </div>

          {/* Penalty Status */}
          <div className="p-3 rounded-md bg-gray-50">
            <div className="flex items-center justify-between mb-2">
              <span className="font-semibold text-gray-700">Penalty Status:</span>
              <span
                className={`font-medium ${
                  player.penalty === "noPenalty" ? "text-green-600" : "text-red-600"
                }`}
              >
                {penaltyDescriptions[player.penalty] || player.penalty}
              </span>
            </div>
            {player.penaltyTimer.started && (
              <div className="flex items-center justify-between mt-2 pt-2 border-t border-gray-200">
                <span className="text-sm text-gray-600">Time Remaining:</span>
                <span className="font-mono text-lg font-bold text-red-600">
                  {formatMMSS(player.penaltyTimer)}
                </span>
              </div>
            )}
          </div>

          {/* Additional Info */}
          <div className="text-xs text-gray-500 text-center pt-2 border-t">
            Double-click robot button to view details
          </div>
        </div>

        {/* Footer */}
        <div className="mt-6 flex justify-end">
          <button
            onClick={onClose}
            className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors font-medium"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};

export default RobotStatusModal;
