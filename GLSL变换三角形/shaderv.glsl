attribute vec4 position;
attribute vec4 positionColor;
attribute vec2 textCoordinate;

uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

varying lowp vec4 varyColor;

varying lowp vec2 varyTextCoord;

void main(){
    varyColor = positionColor;
    varyTextCoord = textCoordinate;
    
    vec4 vPos;
    
    vPos = projectionMatrix * modelViewMatrix * position;
    gl_Position = vPos;
}
