# YAFSM Technical Reference

## Project Structure

### Core Resources (`src/`)
- **StateMachine.gd** - Main state machine resource, manages states and transitions
- **StateMachinePlayer.gd** - Runtime player node, executes state machine logic
- **State.gd** - Base state resource
- **Transition.gd** - Transition resource with conditions and priority
- **Condition.gd** - Base condition class
- **ValueCondition.gd** - Condition with comparison operators (==, !=, <, >, etc.)
- **StackPlayer.gd** - Stack-based state history manager
- **StateDirectory.gd** - Path utilities for nested states

### Condition Types (`src/conditions/`)
- BooleanCondition, IntegerCondition, FloatCondition, StringCondition
- All extend ValueCondition with typed value property

### Editor UI (`scenes/`)
- **StateMachineEditor.tscn/.gd** - Main editor interface
- **FlowChart.gd** - Visual graph editor base
- **FlowChartLayer.gd** - Manages nodes and connections
- **StateMachineEditorLayer.gd** - State machine specific layer with debug visualization
- **StateNode.gd** - Visual state representation
- **TransitionLine.gd** - Visual transition arrow with condition labels
- **TransitionEditor.gd** - Inspector panel for transitions

### Utilities
- **Utils.gd** - Popup positioning, color utilities, line clipping (Cohen-Sutherland)
- **plugin.gd** - Editor plugin registration

## Key Concepts

### State Paths
- States use slash-separated paths: `"parent/child/state"`
- Entry state: `State.ENTRY_STATE`
- Exit state: `State.EXIT_STATE`
- Nested state machines supported

### Transitions
- **From/To**: Source and target state names
- **Priority**: Higher priority transitions checked first
- **Conditions**: Dictionary keyed by condition name
- **use_target_as_trigger**: Auto-trigger feature - uses target state name as implicit trigger

### Parameters
- Global parameters: Shared across state machine
- Local parameters: Override global for specific transitions
- Triggers: Conditions with null value act as boolean flags

### Auto-Trigger Feature
- When enabled, transition implicitly checks for trigger with target state name
- Visual feedback: Blue "→ [StateName]" label on transition arrow
- Reduces redundant trigger definitions

## State Machine Execution

1. **transit(current_state, params, local_params)** - Attempts transition
2. Checks conditions in priority order
3. Returns next state path or empty string
4. Handles nested state machines and exit states

## Editor Integration

### Inspector Plugins
- **TransitionInspector** - Custom UI for Transition resources
- **StateInspector** - Hides default properties for State resources

### Debug Mode
- Real-time parameter visualization
- Condition evaluation coloring (green/red)
- Transition highlighting on state changes
- Tween animations for visual feedback

## File Organization

```
addons/yafsm/
├── src/                    # Core logic
│   ├── states/            # State machine resources
│   ├── transitions/       # Transition resources
│   ├── conditions/        # Condition types
│   └── debugger/          # Debug utilities
├── scenes/                # Editor UI
│   ├── flowchart/         # Graph editor base
│   ├── state_nodes/       # State visualization
│   ├── transition_editors/# Transition UI
│   └── condition_editors/ # Condition UI
├── scripts/               # Utilities
└── assets/                # Icons and fonts
```

## Coding Standards Applied

- Explicit type hints for all variables, parameters, returns
- No comments (self-documenting code)
- Two blank lines between functions
- Normal conditionals over ternary
- Variant type for nullable/flexible values
- Tab indentation

## Common Patterns

### Creating State Machine
```gdscript
var sm: StateMachine = StateMachine.new()
sm.add_state(State.new("idle"))
sm.add_state(State.new("walk"))
var transition: Transition = Transition.new("idle", "walk")
sm.add_transition(transition)
```

### Using Player
```gdscript
var player: StateMachinePlayer = StateMachinePlayer.new()
player.state_machine = sm
player.set_trigger("walk")  # Trigger transition
```

### Condition Evaluation
```gdscript
var condition: IntegerCondition = IntegerCondition.new("speed")
condition.comparation = ValueCondition.Comparation.GREATER
condition.value = 5
var params: Dictionary = {"speed": 10}
condition.compare(params["speed"])  # Returns true
```

## Signal Flow

- `transition_added(transition)` - Emitted when transition added to state machine
- `transition_removed(from, to)` - Emitted when transition removed
- `use_target_as_trigger_changed(enabled)` - Emitted when auto-trigger toggled
- `condition.name_changed(from, to)` - Emitted when condition renamed
- `condition.display_string_changed(display)` - Emitted when condition display updates

## Performance Notes

- Transitions sorted by priority once per transit attempt
- Condition evaluation short-circuits on first match
- Visual updates use Tween for smooth animations
- Node caching in editor to avoid repeated lookups
