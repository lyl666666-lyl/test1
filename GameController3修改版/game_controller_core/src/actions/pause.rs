use serde::{Deserialize, Serialize};

use crate::action::{Action, ActionContext};

/// This struct defines an action for pausing the game (system-level freeze).
/// Unlike Timeout, this does not change the game state - it freezes everything in place.
#[derive(Clone, Debug, Deserialize, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Pause;

impl Action for Pause {
    fn execute(&self, c: &mut ActionContext) {
        // Set the pause flag - this freezes the game without changing state
        c.game.is_paused = true;
        
        // Note: We do NOT change game.state, game.phase, or any other game logic
        // The game state remains exactly as it was (e.g., PLAYING stays PLAYING)
        // Timers will be frozen by the timer update logic checking is_paused
    }

    fn is_legal(&self, c: &ActionContext) -> bool {
        // Can pause at any time except when already paused
        !c.game.is_paused
    }
}
