use serde::{Deserialize, Serialize};

use crate::action::{Action, ActionContext};

/// This struct defines an action for resuming the game from a pause.
/// This unfreezes the game and allows everything to continue from where it was paused.
#[derive(Clone, Debug, Deserialize, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Resume;

impl Action for Resume {
    fn execute(&self, c: &mut ActionContext) {
        // Clear the pause flag - this unfreezes the game
        c.game.is_paused = false;
        
        // Note: We do NOT change game.state, game.phase, or any other game logic
        // The game continues exactly from where it was paused
        // Timers will resume counting by the timer update logic
    }

    fn is_legal(&self, c: &ActionContext) -> bool {
        // Can only resume when paused
        c.game.is_paused
    }
}
