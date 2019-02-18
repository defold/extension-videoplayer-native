package com.defold.android.videoplayer;

import android.content.Context;
import android.util.AttributeSet;
import android.view.SurfaceView;
import android.view.View;

public class VideoView extends SurfaceView implements View.OnClickListener {

	public enum ScaleMode{ Fit, Stretch, Zoom }

	private ScaleMode scaleMode;
	private int width;
	private int height;
	private float aspectRatio;

	public VideoView(Context context) {
		super(context);
		init();
	}
	public VideoView(Context context, AttributeSet attrs) {
		super(context, attrs);
		init();
	}
	public VideoView(Context context, AttributeSet attrs, int defStyleAttr) {
		super(context, attrs, defStyleAttr);
		init();
	}
	public VideoView(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
		super(context, attrs, defStyleAttr, defStyleRes);
		init();
	}

	private void init(){
		scaleMode = ScaleMode.Zoom;
		width = 0;
		height = 0;
		aspectRatio = 1.0f;

		setOnClickListener(this);
	}

	public void setScaleMode(ScaleMode _scaleMode){
		scaleMode = _scaleMode;
	}

	public void setSize(int _width, int _height) {
		width = _width;
		height = _height;
		aspectRatio = (float)width / (float)height;
		requestLayout();
		invalidate();
	}

	@Override
	protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec){
		Logger.log("VideoView: onMeasure");
		try{
			int measuredWidth = MeasureSpec.getSize(widthMeasureSpec);
			int measuredHeight = MeasureSpec.getSize(heightMeasureSpec);

			if(measuredWidth == 0 || measuredHeight == 0){
				setMeasuredDimension(measuredWidth, measuredHeight);
			} else {
				float screenRatio = (float)measuredWidth/(float)measuredHeight;

				switch(scaleMode) {
					case Zoom:
						if(aspectRatio > screenRatio)
						{
							float h = (float)measuredHeight;
							float w = h * aspectRatio;
							setMeasuredDimension((int)w, (int)h);
						} else {
							float w = (float)measuredWidth;
							float h = w / aspectRatio;
							setMeasuredDimension((int)w, (int)h);
						}
						break;
					case Fit:
						if(aspectRatio < screenRatio)
						{
							float h = (float)measuredHeight;
							float w = h * aspectRatio;
							setMeasuredDimension((int)w, (int)h);
						} else {
							float w = (float)measuredWidth;
							float h = w / aspectRatio;
							setMeasuredDimension((int)w, (int)h);
						}
						break;
					case Stretch:
						setMeasuredDimension(measuredWidth, measuredHeight);
						break;
				}
			}
		} catch (Exception e) {
			Logger.log("VideoView: " + e.toString());
			super.onMeasure(widthMeasureSpec, heightMeasureSpec);
		}
	}

	@Override
	public void onClick(View v){
		Logger.log("VideoView: onClick");
		return;
	}
}
