class_name SpriteCollection extends Resource


class CollectedSprite extends Resource:
	@export var rect: Rect2i
	@export var rotated: bool
	@export var custom_texture: Texture2D
	
	func _init(_rect: Rect2i, _rotated: bool) -> void:
		self.rect = _rect
		self.rotated = _rotated
	
	
	func free() -> void:
		custom_texture = null
	
	
	func _to_string() -> String:
		return '{ "rect": %s, "rotated": %s }' % [rect, rotated]

@export var map: Dictionary[StringName, CollectedSprite] = {}
@export var size: Vector2i = Vector2i.ZERO
@export var scale: int = 1
@export var texture: Texture2D


static func load_from_json(input: Dictionary, texture: Texture2D) -> SpriteCollection:
	var collection := SpriteCollection.new()
	collection.texture = texture
	
	var atlas: Dictionary = input.get('ATLAS', {})
	var sprites: Array = atlas.get('SPRITES', [])
	
	var image: Image = null
	var format: Image.Format
	var compressed: bool = false
	
	for sprite: Dictionary in sprites:
		var values: Dictionary = sprite.get('SPRITE', {})
		if values.is_empty():
			continue
		
		var collected := CollectedSprite.new(
			Rect2i(
				Vector2i(values.get('x', 0), values.get('y', 0)),
				Vector2i(values.get('w', 0), values.get('h', 0))
			),
			values.get('rotated', false),
		)
		
		var name := StringName(values.get('name', ''))
		## TODO: make this less hacky of a fix :p
		if collected.rotated:
			if not is_instance_valid(image):
				image = collection.texture.get_image()
				format = image.get_format()
				compressed = image.is_compressed()
				if compressed:
					image.decompress()
			
			var frame := image.get_region(collected.rect)
			frame.rotate_90(COUNTERCLOCKWISE)
			if compressed:
				match format:
					Image.FORMAT_BPTC_RGBA:
						frame.compress(Image.COMPRESS_BPTC)
					_:
						frame.compress(Image.COMPRESS_ETC2)
			
			var image_texture := ImageTexture.create_from_image(frame)
			collected.custom_texture = image_texture
		
		collection.map.set(name, collected)
	
	var metadata: Dictionary = atlas.get('meta', {})
	if metadata.has('size'):
		var raw_size: Dictionary = metadata.get('size', {})
		collection.size = Vector2i(raw_size.get('w', 0), raw_size.get('h', 0))
	collection.scale = int(metadata.get('resolution', '1'))
	
	return collection
