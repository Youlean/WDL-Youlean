#include "IGraphicsCairo.h"
#include "IControl.h"
#include <cmath>
#include "Log.h"

signed int GetSystemVersion();

IGraphicsCairo::IGraphicsCairo(IPlugBaseGraphics* pPlug, int w, int h, int fps)
: IGraphics(pPlug, w, h, fps)
{
  mSurface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, w, h);
  mContext = cairo_create(mSurface);
}


IGraphicsCairo::~IGraphicsCairo()
{
}

void IGraphicsCairo::PrepDraw()
{
}

bool IGraphicsCairo::DrawBitmap(IBitmap& bitmap, const IRECT& dest, int srcX, int srcY, const IChannelBlend* pBlend)
{
  return true;
}

bool IGraphicsCairo::DrawRotatedBitmap(IBitmap& bitmap, int destCtrX, int destCtrY, double angle, int yOffsetZeroDeg, const IChannelBlend* pBlend)
{
  return true;
}

bool IGraphicsCairo::DrawRotatedMask(IBitmap& base, IBitmap& mask, IBitmap& top, int x, int y, double angle, const IChannelBlend* pBlend)
{
  return true;
}

bool IGraphicsCairo::DrawPoint(const IColor& color, float x, float y, const IChannelBlend* pBlend, bool aa)
{
  return true;
}

bool IGraphicsCairo::ForcePixel(const IColor& color, int x, int y)
{
  return true;
}

bool IGraphicsCairo::DrawLine(const IColor& color, float x1, float y1, float x2, float y2, const IChannelBlend* pBlend, bool aa)
{
  return true;
}

bool IGraphicsCairo::DrawArc(const IColor& color, float cx, float cy, float r, float minAngle, float maxAngle, const IChannelBlend* pBlend, bool aa)
{
  return true;
}

bool IGraphicsCairo::DrawCircle(const IColor& color, float cx, float cy, float r, const IChannelBlend* pBlend, bool aa)
{
  return true;
}

bool IGraphicsCairo::RoundRect(const IColor& color, const IRECT& rect, const IChannelBlend* pBlend, int cornerradius, bool aa)
{
  return true;
}

bool IGraphicsCairo::FillRoundRect(const IColor& color, const IRECT& rect, const IChannelBlend* pBlend, int cornerradius, bool aa)
{
  return true;
}

bool IGraphicsCairo::FillIRect(const IColor& color, const IRECT& rect, const IChannelBlend* pBlend)
{
  return true;
}

bool IGraphicsCairo::FillCircle(const IColor& color, int cx, int cy, float r, const IChannelBlend* pBlend, bool aa)
{
  return true;
}

bool IGraphicsCairo::FillTriangle(const IColor& color, int x1, int y1, int x2, int y2, int x3, int y3, const IChannelBlend* pBlend)
{
  return true;
}

bool IGraphicsCairo::FillIConvexPolygon(const IColor& color, int* x, int* y, int npoints, const IChannelBlend* pBlend)
{
  return true;
}

IColor IGraphicsCairo::GetPoint(int x, int y)
{
  return COLOR_BLACK;
}

bool IGraphicsCairo::DrawVerticalLine(const IColor& color, int xi, int yLo, int yHi)
{
  return true;
}

bool IGraphicsCairo::DrawHorizontalLine(const IColor& color, int yi, int xLo, int xHi)
{
  return true;
}

bool IGraphicsCairo::DrawIText(const IText& text, const char* str, IRECT& rect, bool measure)
{
  return true;
}

bool IGraphicsCairo::MeasureIText(const IText& text, const char* str, IRECT& destRect)
{
  return IGraphicsCairo::DrawIText(text, str, destRect, true);
}