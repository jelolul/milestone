extends EditorResourcePreviewGenerator


func _can_generate_small_preview() -> bool:
	return true

func _generate(resource, size, _metadata) -> Texture2D:
	var img: Image = Image.new()

	if "icon" in resource and resource is Achievement:
		if resource.hidden:
			if resource.hidden_icon:
				img = resource.hidden_icon.get_image()
				img.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
		else:
			if resource.icon:
				img = resource.icon.get_image()
				img.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)

	return ImageTexture.create_from_image(img)

func _handles(type) -> bool:
	return type == "Resource"
