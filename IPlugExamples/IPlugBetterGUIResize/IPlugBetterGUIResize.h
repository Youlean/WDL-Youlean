#ifndef __IPLUGBETTERGUIRESIZE__
#define __IPLUGBETTERGUIRESIZE__

#include "IPlug_include_in_plug_hdr.h"
#include "IPlugGUIResize.h"

class IPlugBetterGUIResize : public IPlug
{
public:
  IPlugBetterGUIResize(IPlugInstanceInfo instanceInfo);
  ~IPlugBetterGUIResize();

  void Reset();
  void OnParamChange(int paramIdx);
  void ProcessDoubleReplacing(double** inputs, double** outputs, int nFrames);
  void OnGUIOpen();
  void SetGUILayout(int viewMode, double windowWidth, double windowHeight);

private:
  IGraphics* pGraphics;
  IPlugGUIResize* pGUIResize;

  // Get control numbers. Do this to make gui layout easier
  int background, redKnob, grayKnob, infoText, customControl;
};

class CustomControl : public IControl
{
public:
	CustomControl(IPlugBase *pPlug, IRECT pR, IColor color)
		: IControl(pPlug, pR), mColor(color) {}

	~CustomControl() {}

	// Initialize GUI size here. This will be called after gui resize
	void InitializeGUI(double scaleRatio)
	{
		// For example make this rect halph the size of control rect
		// We could actually just use mRECT, but this is just to demonstrate this function

		drawRect.L = mRECT.L;
		drawRect.T = mRECT.T;
		drawRect.R = mRECT.W() / 2 + mRECT.L;
		drawRect.B = mRECT.B;
		
	}

	bool Draw(IGraphics* pGraphics)
	{
		pGraphics->FillIRect(&mColor, &drawRect);
		return true;
	}

private:
	IRECT drawRect;
	IColor mColor;
};

class viewSelector : public IControl
{
private:
	WDL_String mStr;
	IPlugGUIResize *GUIResize;
	int view_mode;

public:
	viewSelector(IPlugBase* pPlug, IRECT pR, const char* label, IPlugGUIResize *pGUIResize, int viewMode)
		: IControl(pPlug, pR)
	{
		GUIResize = pGUIResize;
		view_mode = viewMode;
		mStr.Set(label);
		mText.mColor = COLOR_WHITE;
		mText.mSize = 24;
	}

	~viewSelector() {}

	bool Draw(IGraphics* pGraphics)
	{
		pGraphics->FillIRect(&COLOR_GRAY, &mRECT, &mBlend);
		char* cStr = mStr.Get();
		return pGraphics->DrawIText(&mText, cStr, &mRECT);
	}

	void OnMouseDown(int x, int y, IMouseMod* pMod)
	{
		GUIResize->SelectViewMode(view_mode);
		GUIResize->ResizeAtGUIOpen();
	}

};
#endif