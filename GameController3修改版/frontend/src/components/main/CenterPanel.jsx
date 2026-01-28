import ClockPanel from "./ClockPanel";
import PenaltyPanel from "./PenaltyPanel";
import StatePanel from "./StatePanel";

const CenterPanel = ({
  game,
  legalGameActions,
  legalPenaltyActions,
  params,
  selectedPenaltyCall,
  setSelectedPenaltyCall,
}) => {
  return (
    <div className="gc-panel flex-1 flex flex-col gap-4 min-w-[300px] overflow-hidden">
      <ClockPanel game={game} legalGameActions={legalGameActions} />
      <StatePanel game={game} params={params} legalGameActions={legalGameActions} />
      <PenaltyPanel
        legalPenaltyActions={legalPenaltyActions}
        selectedPenaltyCall={selectedPenaltyCall}
        setSelectedPenaltyCall={setSelectedPenaltyCall}
      />
    </div>
  );
};

export default CenterPanel;
