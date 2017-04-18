package com.ooyala.android.skin.view;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.os.Handler;
import android.support.v7.widget.AppCompatTextView;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.ViewGroup.MarginLayoutParams;
import android.view.accessibility.CaptioningManager;
import android.widget.FrameLayout;
import android.widget.Scroller;

import com.ooyala.android.captions.ClosedCaptionsStyle;
import com.ooyala.android.item.Caption;

import java.util.ArrayList;
import java.util.Arrays;

public class ClosedCaptionsView extends AppCompatTextView {
  private Caption caption;
  private ClosedCaptionsStyle style;
  private Paint StrokePaint; // Paint for drawing outline
  private Paint textPaint; // Paint for drawing text
  private Rect textBounds; // Rect for a text
  private double textHeight;
  private String existingText = ""; // Store the closed captions text for Roll-up effect
  private String currentText = ""; // The closed captions for this period of time
  private Scroller scroller;

  // Paint-on variables
  private CharSequence paintOnText;
  private int paintOnIndex;
  private long paintOnDelay = 10;
  private final Handler paintOnHandler = new Handler();
  private final Runnable charPainter = new Runnable() {
    @Override
    public void run() {
      setText(paintOnText.subSequence(0, paintOnIndex++));
      if(paintOnIndex <= paintOnText.length()) {
        paintOnHandler.postDelayed(charPainter, paintOnDelay);
      }
    }
  };

  public ClosedCaptionsView(Context context) {
    super(context);
    style = new ClosedCaptionsStyle(context);
    style.backgroundColor = Color.TRANSPARENT;
    textBounds = new Rect();
  }

  public void setCaption(double begin, double end, String text, Double width) {
    setTextColor(Color.GREEN);  //TODO: The TextColour was Transparent and captions are not visible so it has changed to Green for visibilty.
    caption = new Caption(begin, end, text);
    double preBegin = -1;
    if (this.caption != null) {
      preBegin = this.caption.getBegin();
    }
    this.caption = caption;
    if (this.caption != null && (!this.currentText.equals(this.caption.getText()) || preBegin != this.caption.getBegin())) {
      this.currentText = caption.getText();
      setClosedCaptions(text, width);
    } else {
      setBackgroundColor(Color.TRANSPARENT);
      setText("");
    }
  }

  // Set specific text on textview (shared by live streams and normal stream)
  private void setClosedCaptions(String text, Double width) {
    setBackgroundColor(style.backgroundColor);
    // With outline edge type we draw text with Paint so we do not need to show original text in textview
    // However, we still need the original text on textview to figure the position of text for Paint
    // So we set the textColor to transparent for outline edge type
    if (this.style.edgeType == CaptioningManager.CaptionStyle.EDGE_TYPE_OUTLINE) {
      this.setTextColor(Color.TRANSPARENT);
    }

    this.setGravity(Gravity.CENTER_HORIZONTAL | Gravity.TOP);
    String splitText = getSplitTextAndUpdateFrame(text, width);
    setText(splitText);
  }

  public void updateEdgeStyle() {
    if (this.style.edgeType == CaptioningManager.CaptionStyle.EDGE_TYPE_OUTLINE) {// Setup stroke paint;
      this.StrokePaint = new Paint();
      this.StrokePaint.setAntiAlias(true);
      this.StrokePaint.setTextSize(super.getTextSize());
      this.StrokePaint.setStyle(Paint.Style.STROKE);
      this.StrokePaint.setColor(this.style.edgeColor);
      this.StrokePaint.setTypeface(super.getTypeface());
      this.StrokePaint.setFlags(super.getPaintFlags());
      this.StrokePaint.setStrokeWidth(4);

      // Setup text paint
      this.textPaint = new Paint();
      this.textPaint.setAntiAlias(true);
      this.textPaint.setTextSize(super.getTextSize());
      this.textPaint.setStyle(Paint.Style.FILL);
      this.textPaint.setColor(this.style.textColor);
      this.textPaint.setTypeface(super.getTypeface());
      this.textPaint.setFlags(super.getPaintFlags());
      setTextColor(Color.TRANSPARENT);
    } else if (this.style.edgeType == CaptioningManager.CaptionStyle.EDGE_TYPE_DROP_SHADOW) {
      setShadowLayer(4, 4, 4, this.style.edgeColor);
    }
  }

  public void setStyle(ClosedCaptionsStyle style) {
    this.style = style;
    this.setTextSize( TypedValue.COMPLEX_UNIT_SP, style.textSize );
    String testString = "just for height"; // any text including "j" and "f" can define the max height for this font size
    super.getPaint().getTextBounds(testString, 0, testString.length(), this.textBounds);
    this.textHeight = this.textBounds.height() * 1.5;
    this.setTextColor(this.style.textColor);
    this.setTypeface(style.textFont);
    this.updateEdgeStyle();
    this.updateBottomMargin();
  }

  public void updateBottomMargin() {
    MarginLayoutParams params = (MarginLayoutParams) this.getLayoutParams();
    params.bottomMargin = style.bottomMargin;
    this.setLayoutParams(params);
  }

  // Set frame of text view based on the text size
  public String getSplitTextAndUpdateFrame(String text, Double allowedWidth) {
    // Current maxWidth of closed caption view in this device
    int maxWidth = (int)(allowedWidth * 0.9 - this.getPaddingLeft() - this.getPaddingRight());
    ArrayList<String> lines = new ArrayList<String>(Arrays.asList(text.split("\n")));
    this.setText(text); // setText temporally to help calculate where those text should be when they are added to textView

    // Find the width of the longest line in currently closed caption
    // Set width of closed caption to that width if the longest line is shorter than the maxWidth
    // Otherwise, set width of closed caption to the maxWidth for this device
    int longestLineWidth = 0;
    for (String line : lines) {
      super.getPaint().getTextBounds(line, 0, line.length(), this.textBounds);
      if (this.textBounds.width() > longestLineWidth) {
        longestLineWidth = this.textBounds.width();
        if (this.textBounds.width() >= maxWidth) {
          break;
        }
      }
    }
    int width = longestLineWidth;
    ArrayList<String> splitLines = new ArrayList<String>();

    int lineNum = lines.size();
    String splitText = text;
    if (longestLineWidth >= maxWidth) {
      // LongestLineWidth is greater than maxWidth so we need to split at least one line of this closed caption
      width = maxWidth;
      Rect currentBound = new Rect();
      for (String line : lines) {
        int prevWhiteSpaceIndex = 0; // The index where the '\n' char should be insert if this line need to be split
        for (int i = 0; i < line.length(); i++) {
          String subline = line.substring(0, i + 1);
          super.getPaint().getTextBounds(subline, 0, subline.length(), currentBound);
          // This line need to be split
          // Currently we only split once at most per line so if we get a super lone line
          // some later part of that line could be invisiable
          if (currentBound.width() > width) {
            splitLines.add(line.substring(0, prevWhiteSpaceIndex));
            splitLines.add(line.substring(prevWhiteSpaceIndex + 1, line.length()));
            lineNum++;
            break;
          }
          // This line does not need to be split
          if (i == line.length() - 1) {
            splitLines.add(line);
          }
          if (line.charAt(i) == ' ') {
            prevWhiteSpaceIndex = i;
          }
        }
      }
      // Construct the new text based on frame width
      splitText = splitLines.get(0);
      for (int i = 1; i < splitLines.size(); i++) {
        splitText = splitText + "\n" + splitLines.get(i);
      }
    }

    // If we always use fix size frame for roll-up
    // For paint-on and pop-on we change the frame size based on how long the text is and the font size

    // Set 150 as the smallest width for shortest text
    this.setLayoutParams(
        new FrameLayout.LayoutParams(
            Math.max(150, width * 10 / 9 + this.getPaddingLeft() + this.getPaddingRight()),
            (int)(lineNum * this.textHeight + (this.getPaddingBottom() + this.getPaddingTop())),
            Gravity.CENTER_HORIZONTAL | Gravity.BOTTOM));
    this.updateBottomMargin();

    return splitText;
  }

  // Draw text and stroke for outline edge type
  @Override
  public void onDraw(Canvas canvas) {
    // Only draw outline when the edge type is EDGE_TYPE_OUTLINE
    if (this.style.edgeType == CaptioningManager.CaptionStyle.EDGE_TYPE_OUTLINE) {
      String[] lines = super.getText().toString().split("\n");

      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (this.getLayout() != null && i < this.getLineCount()) {
          int currentVeriticalOffset = this.getLayout().getLineTop(i) + this.getBaseline();
          super.getPaint().getTextBounds(line, 0, line.length(), this.textBounds);
          int leftPadding = (int) ((this.getWidth() - this.textBounds.width()) * 0.5); // Center the text

          canvas.drawText(line, leftPadding, currentVeriticalOffset, this.StrokePaint);
          canvas.drawText(line, leftPadding, currentVeriticalOffset, this.textPaint);
        }
      }
    }
    super.onDraw(canvas);
  }
}
