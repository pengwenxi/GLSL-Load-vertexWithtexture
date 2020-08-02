precision highp float;
varying lowp vec4 varyColor;
varying lowp vec2 varyTextCoord;
uniform sampler2D colorMap;
void main(){
    lowp vec4 temp = texture2D(colorMap,varyTextCoord);
    gl_FragColor = temp;
}
