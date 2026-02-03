extends EditorResourcePreviewGenerator


func _can_generate_small_preview() -> bool:
	return true

func _generate(resource, size, _metadata) -> Texture2D:
	var img: Image = Image.new()

	if "icon" in resource and resource is Achievement:
		var tex: Texture2D = null

		if resource.hidden and resource.hidden_icon:
			tex = resource.hidden_icon
		elif not resource.hidden and resource.icon:
			tex = resource.icon

		if tex:
			img = tex.get_image()

	if img.is_empty():
		return null
	
	return ImageTexture.create_from_image(img)

func _handles(type) -> bool:
	return type == "Resource"
