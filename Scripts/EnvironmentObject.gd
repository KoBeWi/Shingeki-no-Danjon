extends Sprite

enum PLACEMENT{ANY, SIDE_WALL, NO_WALL}

export(PLACEMENT) var placement = 0
export var offset_position = Vector2(0, 0)
export var variants = ""
export var can_flip_h = false