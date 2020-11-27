// Processing_audio_vinyl_12inch.pde

import processing.pdf.*;

enum Phase { BISCUIT, DROP, LEADIN, TRACK, LEADOUT, LOCKED, LIFT }

final float FPS = 60.3;
final float RPM = 33.333;
final int REPS = 5;
final float leadinPitch = 0.9;
final float leadinRevolutions = 3;
final float leadoutPitch = 6.4;
final float leadoutRevolutions = 4;
final float maxOuterDiameter = 292.6;
final float minInnerDiameter = 115.0;
final float startAngle = 120 / 360.0 * TWO_PI;
final float vinylDiameter = 300;
final int borderPixels = 10;
final int backgrounColour = 255;
final int grooveColour = 192;
final int textColour = 32;

Phase currentPhase;
float currentAngle;
float currentRadius;
float trackChord;
float trackPitch;
float drawingFactor;

String consoleText = "";

void setup() {
  size(640, 480);
  frameRate(FPS);
  background(backgrounColour);
  initRealistic();
}

void draw() {
  switch (currentPhase) {
  case DROP:
    // beginRecord(PDF, "Line-#######.pdf");
  case LEADIN:
  case TRACK:
  case LEADOUT:
  case LOCKED:
    for (int count = REPS; count > 0; count--){
      cutVinyl();
    }
    break;
  default:
    // endRecord();
    break;
  }

  fill(backgrounColour);
  rect(5, 5, 50, 15);
  fill(textColour);
  text(String.format("%5.1f fps", frameRate), 5, 15);
}

void initRealistic() {
  currentAngle = startAngle;
  currentPhase = Phase.DROP;
  currentRadius = maxOuterDiameter / 2;
  drawingFactor = (min(width, height) - 2 * borderPixels) / vinylDiameter;
  trackChord = getTrackChord();
  trackPitch = ((maxOuterDiameter / 2 - leadinRevolutions * leadinPitch) - (minInnerDiameter / 2 + leadoutRevolutions * leadoutPitch)) / (getTrackDuration() * getRevolutionsPerSecond());
}

void cutVinyl() {
  float xPoint = drawingFactor * currentRadius * sin(currentAngle);
  float yPoint = drawingFactor * currentRadius * cos(currentAngle);

  pushMatrix();

  translate(width / 2 + xPoint, height / 2 - yPoint);

  noStroke();
  rotate(currentAngle);
  fill(grooveColour);

  ellipse(0, 0, trackChord, 1.0);

  popMatrix();

  rotateVinyl();
}

int getVinylColour() {
  return 0;
}

static float totalAngle = 0;
void rotateVinyl() {
  float anglePerRotation = TWO_PI * getRevolutionsPerSecond() / (REPS * getFPS());

  currentAngle -= anglePerRotation;
  totalAngle += anglePerRotation;

  // Keep currentAngle +ve
  if (currentAngle < 0.0) {
    currentAngle += TWO_PI;
  }

  // Do once a revolution stuff
  if (totalAngle >= TWO_PI) {
    trackChord = getTrackChord();
    switch (currentPhase) {
    case DROP:
      currentPhase = Phase.LEADIN;
      break;
    case LEADIN:
      if (currentRadius <= maxOuterDiameter / 2 - leadinRevolutions * leadinPitch) {
        currentPhase = Phase.TRACK;
      }
      break;
    case TRACK:
      if (currentRadius <= minInnerDiameter / 2 + leadoutRevolutions * leadoutPitch) {
        currentPhase = Phase.LEADOUT;
      }
      break;
    case LEADOUT:
      if (currentRadius <= minInnerDiameter / 2) {
        currentPhase = Phase.LOCKED;
      }
      break;
    case LOCKED:
      currentPhase = Phase.LIFT;
      break;
    default:
      break;
    }
    totalAngle -= TWO_PI;
  }

  float curPitch = 0; // LOCKED
  switch (currentPhase) {
  case DROP:
  case LEADIN:
    curPitch = leadinPitch;
    break;
  case TRACK:
    curPitch = trackPitch;
    break;
  case LEADOUT:
    curPitch = leadoutPitch;
  default:
    break;
  }
  currentRadius -= curPitch * getRevolutionsPerSecond() / (REPS * getFPS());

  String curText = String.format("currentPhase %s curPitch %5.2f trackChord %5.2f", currentPhase, curPitch, trackChord);
  if (!curText.equals(consoleText)) {
    println(curText);
    consoleText = curText;
  }
}

boolean liftStylus() {
  return currentRadius <= minInnerDiameter / 2;
}

float getTrackDuration() {
  return 2.5 * 60; // 2 minute 30 second track
}

float getFPS() {
  return (frameCount > 20) ? frameRate : FPS;
}

float getRevolutionsPerSecond() {
  return RPM / 60;
}

float getTrackChord() {
  return floor(TWO_PI * drawingFactor * currentRadius / (REPS * getFPS()) + 1);
}
