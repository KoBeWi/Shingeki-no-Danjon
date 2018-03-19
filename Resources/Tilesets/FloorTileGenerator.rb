TILE = '[node name="Floor2" type="Sprite" parent="." index="%{id}"]

position = Vector2( %{x}, 400 )
texture = ExtResource( 1 )
region_enabled = true
region_rect = Rect2( %{rectx}, %{recty}, 80, 80 )
_sections_unfolded = [ "Region" ]'

10.times do |i|
	puts(TILE % {id: 25+i, rectx: i*80, recty: 320, x: i*80})
end