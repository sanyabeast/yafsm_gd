# gd-YAFSM (Fork)

**Original Author:** [imjp94](https://github.com/imjp94/gd-YAFSM)  
**Fork Maintainer:** [@sanyabeast](https://github.com/sanyabeast)

This is a fork of gd-YAFSM with additional features and enhancements.

## Fork Enhancements

### Auto-Trigger Feature

Transitions can now use the target state name as an implicit trigger, reducing redundant trigger definitions.

**How to use:**
1. Select a transition in the state machine editor
2. Check the **"Auto-Trigger"** checkbox in the transition inspector
3. The transition will now trigger when you call `set_trigger(target_state_name)`

**Example:**
```gdscript
# Transition: Idle -> Jump with Auto-Trigger enabled
player.set_trigger("Jump")  # Uses target state name as trigger
```

**Visual Feedback:**
- When Auto-Trigger is enabled, a blue label **"→ [StateName]"** appears on the transition arrow
- The label updates instantly when toggling the checkbox
- Works alongside regular conditions

**Benefits:**
- More intuitive API (trigger name matches target state)
- Cleaner state machine graphs
- Less manual trigger condition creation

---

# Documentation

## Classes

All of the class are located in `res://addons/yafsm/src` but you can just preload `res://addons/yafsm/YAFSM.gd` to import all class available:

```gdscript
const YAFSM = preload("res://addons/yafsm/YAFSM.gd")
const StackPlayer = YAFSM.StackPlayer
const StateMachinePlayer = YAFSM.StateMachinePlayer
const StateMachine = YAFSM.StateMachine
const State = YAFSM.State
```

### Node

- [StackPlayer](src/stack_player.gdd) ![StackPlayer icon](assets/icons/stack_player_icon.png)
  > Manage stack of item, use push/pop function to set current item on top of stack
  - `current # Current item on top of stack`
  - `stack`
  - signals:
    - `pushed(to) # When item pushed to stack`
    - `popped(from) # When item popped from stack`
- [StateMachinePlayer](src/state_machine_player.gd)(extends StackPlayer) ![StateMachinePlayer icon](assets/icons/state_machine_player_icon.png)
  > Manage state based on `StateMachine` and parameters inputted
  - `state_machine # StateMachine being played`
  - `active # Activeness of player`
  - `autostart # Automatically enter Entry state on ready if true`
  - `process_mode # ProcessMode of player`
  - signals:
    - `transited(from, to) # Transition of state`
    - `entered(to) # Entry of state machine(including nested), empty string equals to root`
    - `exited(from) # Exit of state machine(including nested, empty string equals to root`
    - `updated(state, delta) # Time to update(based on process_mode), up to user to handle any logic, for example, update movement of KinematicBody`

### Control

- [StackPlayerDebugger](src/debugger/StackPlayerDebugger.gd)
  > Visualize stack of parent StackPlayer on screen

### Reference

- [StateDirectory](src/state_directory.gd)
  > Convert state path to directory object for traversal, mainly used for nested state

### Resource

Relationship between all `Resource`s can be best represented as below:

```gdscript
var state_machine = state_machine_player.state_machine
var state = state_machine.states[state_name] # keyed by state name
var transition = state_machine.transitions[from][to] # keyed by state name transition from/to
var condition = transition.conditions[condition_name] # keyed by condition name
```

> For normal usage, you really don't have to access any `Resource` during runtime as they only store static data that describe the state machine, accessing `StackPlayer`/`StateMachinePlayer` alone should be sufficient.

- [State](src/states/state.gd)
  > Resource that represent a state
  - `name`
- [StateMachine](src/states/state_machine.gd)(`extends State`) ![StateMachine icon](assets/icons/state_machine_icon.png)
  > `StateMachine` is also a `State`, but mainly used as container of `State`s and `Transitions`s
  - `states`
  - `transitions`
- [Transition](src/transitions/transition.gd)
  > Describing connection from one state to another, all conditions must be fulfilled to transit to next state
  - `from`
  - `to`
  - `conditions`
  - `priority` - Higher priority transitions are evaluated first
  - `use_target_as_trigger` - When enabled, uses target state name as implicit trigger
- [Condition](src/conditions/condition.gd)
  > Empty condition with just a name, treated as trigger
  - `name`
- [ValueCondition](src/conditions/value_condition.gd)(`extends Condition`)
  > Condition with value, fulfilled by comparing values based on comparation
  - `comparation`
  - `value`
- [BooleanCondition](src/conditions/boolean_condition.gd)(`extends ValueCondition`)
- [IntegerCondition](src/conditions/integer_condition.gd)(`extends ValueCondition`)
- [FloatCondition](src/conditions/float_condition.gd)(`extends ValueCondition`)
- [StringCondition](src/conditions/string_condition.gd)(`extends ValueCondition`)
