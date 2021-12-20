shader_type canvas_item;

uniform vec2 player_position;
uniform vec4 color : hint_color = vec4(0.305, 0.298, 0.341,1);
uniform float dist1=0.1;
uniform float dist2 = 0.15;

uniform float mult = 0.56;

void fragment(){
	float transp = 0.0;
	
	float val = distance(vec2(UV.x, UV.y*mult), vec2(player_position.x, player_position.y*mult));

	if(val < dist1)
	{
		transp = 0.0;
		
	}else if(val < dist2)
	{
		transp=0.5;
	}else{
		transp=1.0;
	}	
	COLOR = vec4(color.x, color.y, color.z, transp);
}