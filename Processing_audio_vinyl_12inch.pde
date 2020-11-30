// Processing_audio_vinyl_12inch.pde

import ddf.minim.*;
import processing.pdf.*;

enum Phase { BISCUIT, DROP, LEADIN, TRACK, LEADOUT, LOCKED, LIFT }

final float FPS = 60.3;
final float RPM = 33.333;
final int REPS = 5;
final float holeDiameter = 7.2;
final float leadinPitch = 0.9;
final float leadinRevolutions = 3;
final float leadoutPitch = 6.4;
final float leadoutRevolutions = 4;
final float maxOuterDiameter = 292.6;
final float minInnerDiameter = 115.0;
final float startAngle = 120 / 360.0 * TWO_PI;
final float vinylDiameter = 300;
final int borderPixels = 10;
final int backgroundColour = 255;
final int grooveColour = 192;
final int labelTextColour = 192;
final int textColour = 32;

Phase currentPhase;
float currentAngle;
float currentRadius;
float trackChord;
float trackPitch;
float drawingFactor;
boolean writingPDF;
boolean enablePDF;

PGraphics vinylCutout;

Minim minim;
AudioPlayer player;
String fileRegEx = "^.+\\.(wav|aiff|au|snd|mp3)$";

String consoleText = "";

void setup() {
  size(640, 480);
  frameRate(FPS);
  background(backgroundColour);

  enablePDF = initAudio();
  writingPDF = false;

  initRealistic();
}

void draw() {
  switch (currentPhase) {
  case BISCUIT:
    if (enablePDF) {
      if (!writingPDF) {
        beginRecord(PDF, generatePDFFilename());
        placeVinylBiscuit();
        writingPDF = true;
      }
    }
    else {
      pourBiscuitSplatter();
    }
    break;
  case DROP:
  case LEADIN:
  case TRACK:
  case LEADOUT:
  case LOCKED:
    for (int count = REPS; count > 0; count--) {
      cutVinyl();
    }
    break;
  case LIFT:
    if (enablePDF) {
      if (writingPDF) {
        endRecord();
        writingPDF = false;
      } else {
        exit();
      }
    } 
  default:
    break;
  }

  if (!writingPDF) {
    noStroke();
    fill(backgroundColour);
    rect(5, 5, 50, 15);
    fill(textColour);
    textSize(12);
    text(String.format("%5.1f fps", frameRate), 5, 15);
  }
}

boolean initAudio() {
  String filename = getNextAudioFilename(dataPath(""));
  if (filename != null) {
    minim = new Minim(this);
    player = minim.loadFile(filename, 1024);
    return true;
  }
  return false;
}

void initRealistic() {
  currentAngle = startAngle;
  currentPhase = Phase.BISCUIT;
  currentRadius = 0;
  drawingFactor = (min(width, height) - 2 * borderPixels) / vinylDiameter;
  trackPitch = ((maxOuterDiameter / 2 - leadinRevolutions * leadinPitch) - (minInnerDiameter / 2 + leadoutRevolutions * leadoutPitch)) / (getTrackDuration() * getRevolutionsPerSecond());
  vinylCutout = cutoutCircle(vinylDiameter * drawingFactor, vinylDiameter * drawingFactor);
  vinylCutout = cutoutHole(vinylCutout);
}

void placeVinylBiscuit() {
  pushMatrix();
  translate(width / 2, height / 2);
  image(vinylCutout, -vinylCutout.width / 2, -vinylCutout.height / 2);
  popMatrix();
  currentPhase = Phase.DROP;
  currentRadius = maxOuterDiameter / 2;
  trackChord = getTrackChord();
}

void pourBiscuitSplatter() {
  float xPoint = drawingFactor * currentRadius;
  float yPoint = drawingFactor * currentRadius;

  pushMatrix();
  translate(width / 2, height / 2);

  int offsetToCentre = min(vinylCutout.width, vinylCutout.height) / 2;
  int background = vinylCutout.get(0, 0);

  for (int y = -(int)yPoint; y <= (int)yPoint; y++) {
    color cutoutColour = vinylCutout.get((int)(offsetToCentre + xPoint), (int)(offsetToCentre + y));
    if (cutoutColour != background) {
      color vinylColour = getVinylColour(-xPoint, y);
      stroke(vinylColour);
      fill(vinylColour);
      ellipse(-xPoint, y, 1.0, 1.0);
      vinylColour = getVinylColour(xPoint, y);
      stroke(vinylColour);
      fill(vinylColour);
      ellipse(xPoint, y, 1.0, 1.0);
    }
  }

  for (int x = -(int)xPoint; x <= (int)xPoint; x++) {
    color cutoutColour = vinylCutout.get((int)(offsetToCentre + x), (int)(offsetToCentre + yPoint));
    if (cutoutColour != background) {
      color vinylColour = getVinylColour(x, -yPoint);
      stroke(vinylColour);
      fill(vinylColour);
      ellipse(x, -yPoint, 1.0, 1.0);
      vinylColour = getVinylColour(x, yPoint);
      stroke(vinylColour);
      fill(vinylColour);
      ellipse(x, yPoint, 1.0, 1.0);
    }
  }

  popMatrix();

  currentRadius += 1.0 / drawingFactor;

  if (currentRadius > vinylDiameter / 2) {
    currentPhase = Phase.DROP;
    currentRadius = maxOuterDiameter / 2;
    trackChord = getTrackChord();
  }
}

void cutVinyl() {
  float xPoint = drawingFactor * currentRadius * sin(currentAngle);
  float yPoint = drawingFactor * currentRadius * cos(currentAngle);

  pushMatrix();

  translate(width / 2 + xPoint, height / 2 - yPoint);

  noStroke();
  rotate(currentAngle);
  fill(grooveColour);

  ellipse(0, 0, trackChord, getAudioLevel());

  popMatrix();

  rotateVinyl();
}

final color[] splatterColours = {#87FF2A, #E936A7};
color getVinylColour(float x, float y) {
  float value = noise((width + x) * 0.02, (height + y) * 0.01);
  int elem = (int)map(value, 0.0, 1.0, 0, splatterColours.length);
  return splatterColours[elem];
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
      dumpMetaData();
      currentPhase = Phase.LEADIN;
      break;
    case LEADIN:
      if (currentRadius <= maxOuterDiameter / 2 - leadinRevolutions * leadinPitch) {
        currentPhase = Phase.TRACK;
        if (player != null) {
          player.play();
        }
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
  if (player != null) {
    int m = player.length();
    println("Time: " + getFormattedDuration(m));
    return m / 1000.0;
  }
  return 2.5 * 60; // 2 minute 30 second track
}

String getFormattedDuration(int m) {
  return String.format("%d.%02d", floor(m / 60000), floor((m / 1000) % 60));
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

float getAudioLevel() {
  if (currentPhase == Phase.TRACK && player != null) {
    return 1.0 + drawingFactor * trackPitch * (player.left.level() + player.right.level()) / 2;
  }
  return 1.0;
}

PGraphics cutoutCircle(float w, float h) {
  PGraphics circle = createGraphics((int)w, (int)h);
  circle.beginDraw();
  circle.background(255);
  circle.noStroke();
  circle.fill(0);
  circle.ellipse(w / 2, h / 2, w, h);
  circle.endDraw();
  return circle;
}

PGraphics cutoutHole(PGraphics cutout) {
  cutout.beginDraw();
  cutout.stroke(255);
  cutout.fill(255);
  cutout.ellipse(cutout.width / 2, cutout.height / 2, drawingFactor * holeDiameter, drawingFactor * holeDiameter);
  cutout.endDraw();
  return cutout;
}

// This function returns all the files in a directory as an array of Strings
String[] listFileNames(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    String names[] = file.list();
    return names;
  } else {
    // If it's not a directory
    return null;
  }
}

static String curAudioFile;
String getNextAudioFilename(String path) {
  boolean seen = false;
  String firstName = null;
  String[] filenames = listFileNames(path);
  if (filenames != null) {
    for (String name : filenames) {
      if (name.matches(fileRegEx)) {
        if (firstName == null) {
          firstName = name;
        }
        if (seen) {
          curAudioFile = name; // Next file
          break;
        }
        if (name.equals(curAudioFile)) {
          seen = true;
        }
      }
    }
  }
  if (!seen && firstName != null) {
    curAudioFile = firstName;
  }

  return curAudioFile;
}

String generatePDFFilename() {
  String file = curAudioFile.substring(0, curAudioFile.lastIndexOf('.'));
  return String.format("%4d-%02d-%02d-%02d%02d_%s.pdf", year(), month(), day(), hour(), minute(), file);
}

void dumpMetaData() {
  if (player != null) {
    AudioMetaData meta = player.getMetaData();
    pushMatrix();
    int size = (int)(5 * drawingFactor);
    int y = 2 * size;
    fill(labelTextColour);
    textSize(size);
    translate(width / 2, height / 2);
    String txt = meta.title();
    text(txt, -size * txt.length() / 4, y += size);
    txt = meta.composer();
    if (txt != null && txt != "") {
      text("(" + txt + ")", -size * (txt.length() + 2) / 4, y += size);
    }
    txt = "Time: " + getFormattedDuration(player.length());
    text(txt, -size * txt.length() / 4, y += size);
    txt = meta.album();
    if (txt != null && txt != "") {
      text(txt, -size * txt.length() / 4, y += size);
    }
    txt = meta.author();
    text(txt, -size * txt.length() / 4, y += size);
    txt = meta.date();
    text(txt, -size * txt.length() / 4, y += size);
    popMatrix();
  }
}
