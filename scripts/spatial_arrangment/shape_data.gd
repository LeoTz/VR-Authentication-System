extends Resource
class_name ShapeData


enum Types { CUBE, SPHERE, CYLINDER, TORUS, EMPTY }
enum Colors { RED, GREEN, BLUE, YELLOW, EMPTY }

@export var type: Types
@export var color: Colors

func _init(_type : Types = Types.EMPTY, _color : Colors = Colors.EMPTY) -> void:
	self.type = _type
	self.color = _color
