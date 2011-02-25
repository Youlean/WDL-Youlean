#include "../swell/swell.h"

#include "virtwnd-controls.h"


@class VWndNSAccessibility;
static VWndNSAccessibility *GetVWndNSAccessible(WDL_VWnd *vwnd);

class VWndBridgeNS : public WDL_VWnd_IAccessibleBridge
{
public:
  VWndBridgeNS() { }
  ~VWndBridgeNS() { }
  virtual void Release() 
  {  
    if (par) 
    {
      [par release];
      par=0;
    }
    vwnd=0; 
  }
  
  VWndNSAccessibility *par;
  WDL_VWnd *vwnd;
};

@interface VWndNSAccessibility : NSObject
{
@public
  VWndBridgeNS *m_br;
}
-(id) initWithVWnd:(WDL_VWnd *)vw;
-(void)dealloc;



// attribute methods
- (NSArray *)accessibilityAttributeNames;
- (id)accessibilityAttributeValue:(NSString *)attribute;
- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute;
- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute;

// parameterized attribute methods
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
- (NSArray *)accessibilityParameterizedAttributeNames;
- (id)accessibilityAttributeValue:(NSString *)attribute forParameter:(id)parameter;
#endif

// action methods
- (NSArray *)accessibilityActionNames;
- (NSString *)accessibilityActionDescription:(NSString *)action;
- (void)accessibilityPerformAction:(NSString *)action;

// Return YES if the UIElement doesn't show up to the outside world - i.e. its parent should return the UIElement's children as its own - cutting the UIElement out. E.g. NSControls are ignored when they are single-celled.
- (BOOL)accessibilityIsIgnored;

// Returns the deepest descendant of the UIElement hierarchy that contains the point. You can assume the point has already been determined to lie within the receiver. Override this method to do deeper hit testing within a UIElement - e.g. a NSMatrix would test its cells. The point is bottom-left relative screen coordinates.
- (id)accessibilityHitTest:(NSPoint)point;

// Returns the UI Element that has the focus. You can assume that the search for the focus has already been narrowed down to the reciever. Override this method to do a deeper search with a UIElement - e.g. a NSMatrix would determine if one of its cells has the focus.
- (id)accessibilityFocusedUIElement;


@end

static WDL_VWnd *__focus;

@implementation VWndNSAccessibility
-(id) initWithVWnd:(WDL_VWnd *)vw
{
  if ((self = [super init]))
  {
    m_br = new VWndBridgeNS;
    m_br->par = self;
    m_br->vwnd = vw;
    vw->SetAccessibilityBridge(m_br);
  }
  return self;
}
-(void)dealloc
{
  if (m_br->vwnd)
  {
    if (__focus == m_br->vwnd) __focus=0;
    m_br->vwnd->SetAccessibilityBridge(NULL);
    m_br->vwnd = NULL;
    delete m_br;
  }
  [super dealloc];
}

- (NSArray *)accessibilityAttributeNames
{
  NSString *s[32];
  int sidx=0;
  const char *type = NULL;
  if (m_br->vwnd)
  {
    type = m_br->vwnd->GetType();
    if (!type) type = "";
  }
  if (type)
  {
//    if (m_br->vwnd->GetNumChildren()) 
    {
      s[sidx++] = NSAccessibilityChildrenAttribute;
      s[sidx++] = NSAccessibilityVisibleChildrenAttribute;
    }
    s[sidx++]=NSAccessibilityTitleAttribute;
        
    if (!strcmp(type,"vwnd_iconbutton")) s[sidx++] = NSAccessibilityEnabledAttribute;
    
    s[sidx++] = NSAccessibilityFocusedAttribute;
    s[sidx++] = NSAccessibilityParentAttribute;
    
    RECT r;
    m_br->vwnd->GetPosition(&r);
    if (m_br->vwnd->IsVisible() && r.right>r.left && r.bottom>r.top)
    {
      s[sidx++] = NSAccessibilityPositionAttribute;
      s[sidx++] = NSAccessibilitySizeAttribute;
    }
    
    s[sidx++] = NSAccessibilityRoleAttribute;
    s[sidx++] = NSAccessibilityRoleDescriptionAttribute;
    
    if (!strcmp(type,"vwnd_statictext")) 
    {
  //    s[sidx++]=NSAccessibilityDescriptionAttribute;
//      s[sidx++]=NSAccessibilityValueDescriptionAttribute;
    }
    
    s[sidx++] = NSAccessibilityWindowAttribute;
  }

  return [NSArray arrayWithObjects:s count:sidx];
}

- (id)accessibilityAttributeValue:(NSString *)attribute
{
  if (!m_br->vwnd) return nil;
  const char *type = m_br->vwnd->GetType();
  if (!type) type="";
  
  //NSLog(@"Requesting attribute: %@ %s %p\n",attribute,type,m_br->vwnd);
  
  int a = [attribute isEqual:NSAccessibilityChildrenAttribute]?1:0;
  if (!a) a= [attribute isEqual:NSAccessibilityVisibleChildrenAttribute]?2:0;
  if (a) // if 2, only add visible items
  {
    int nc = m_br->vwnd->GetNumChildren();
    if (!nc) return nil;
    NSMutableArray *ar = [NSMutableArray arrayWithCapacity:nc];
    int x;
    for (x=0;x<nc;x++)
    {
      WDL_VWnd *ch = m_br->vwnd->EnumChildren(x);
      if (!ch) continue;
      RECT r;
      ch->GetPosition(&r);
      if (a==1 || (ch->IsVisible() && r.right>r.left && r.bottom>r.top))
      {
        VWndNSAccessibility *cid = GetVWndNSAccessible(ch);
        if (cid)
        {
          [ar addObject:cid];
          [cid release];
        }
      }
    }
    return NSAccessibilityUnignoredChildren(ar);
  }

  if ([attribute isEqual:NSAccessibilityEnabledAttribute])
  {
    if (!strcmp(type,"vwnd_iconbutton"))
    {
      return [NSNumber numberWithBool:!!((WDL_VirtualIconButton *)m_br->vwnd)->GetEnabled()];
    }
    return nil;
  }
  if ([attribute isEqual:NSAccessibilityFocusedAttribute])
  {
    return [NSNumber numberWithBool:__focus == m_br->vwnd]; // todo focus bleh
  }
  if ([attribute isEqual:NSAccessibilityParentAttribute])
  {
    WDL_VWnd *parw = m_br->vwnd->GetParent();
    if (parw) 
    {
      VWndNSAccessibility *cid = GetVWndNSAccessible(parw);
      if (cid) return NSAccessibilityUnignoredAncestor([cid autorelease]);      
    }
    HWND h =m_br->vwnd->GetRealParent(); 
    if (h) return NSAccessibilityUnignoredAncestor((id)h);
    return NULL;
  }
  if ([attribute isEqual:NSAccessibilityPositionAttribute])
  {
    RECT r;
    m_br->vwnd->GetPosition(&r);
    r.top = r.bottom; // this wants the lower left corner
    WDL_VWnd *p = m_br->vwnd->GetParent();
    while (p)
    {
      RECT tr;
      p->GetPosition(&tr);
      r.left += tr.left;
      r.top += tr.top;
      p = p->GetParent();
    }
    HWND h = m_br->vwnd->GetRealParent();
    if (h)
    {
      ClientToScreen(h,(LPPOINT)&r);
    }
    //printf("position of (%s) %d,%d\n",m_br->vwnd->GetAccessDesc()?m_br->vwnd->GetAccessDesc():"nul",r.left,r.top);
    return [NSValue valueWithPoint:NSMakePoint(r.left,r.top)];
  }
  if ([attribute isEqual:NSAccessibilitySizeAttribute])
  {
    RECT r;
    m_br->vwnd->GetPosition(&r);
//    printf("size of (%s) %d,%d\n",m_br->vwnd->GetAccessDesc()?m_br->vwnd->GetAccessDesc():"nul",r.right-r.left,r.bottom-r.top);
    return [NSValue valueWithSize:NSMakeSize(r.right-r.left,r.bottom-r.top)];
  }
  if ([attribute isEqual:NSAccessibilityRoleAttribute])
  {
    if (!strcmp(type,"vwnd_statictext")) return NSAccessibilityButtonRole; // fail: seems to need 10.5+ to deliver text? NSAccessibilityStaticTextRole;
    if (!strcmp(type,"vwnd_slider")) return NSAccessibilitySliderRole;
    if (!strcmp(type,"vwnd_combobox")) return NSAccessibilityPopUpButtonRole;
    if (!strcmp(type,"vwnd_iconbutton"))
    {
      WDL_VirtualIconButton *b = (WDL_VirtualIconButton *)m_br->vwnd;
      if (b->GetCheckState()>=0)
        return NSAccessibilityCheckBoxRole;
      return NSAccessibilityButtonRole;
    }
    return NSAccessibilityUnknownRole;
  }
  if ([attribute isEqual:NSAccessibilityTitleAttribute] || [attribute isEqual:NSAccessibilityDescriptionAttribute])// || [attribute isEqual:NSAccessibilityValueDescriptionAttribute])
  {
    const char *str=NULL;
    int cs=-1;
    if (!strcmp(type,"vwnd_statictext"))
    {
      WDL_VirtualStaticText *t = (WDL_VirtualStaticText *)m_br->vwnd;
      str = t->GetText();
    }
    if (!strcmp(type,"vwnd_combobox"))
    {
      WDL_VirtualComboBox *cb = (WDL_VirtualComboBox *)m_br->vwnd;
      str = cb->GetItem(cb->GetCurSel());
    }
    if (!strcmp(type,"vwnd_iconbutton")) 
    {
      WDL_VirtualIconButton *b = (WDL_VirtualIconButton *)m_br->vwnd;
      str = b->GetTextLabel();
      cs = b->GetCheckState();
    }
    char buf[2048];
    if (!str || !*str) str= m_br->vwnd->GetAccessDesc();
    else
    {
      const char *p = m_br->vwnd->GetAccessDesc();
      if (p && *p)
      {
        char buf[1024];
        sprintf(buf,"%.512s: %.512s",p,str);
        str=buf;
      }
    }

  
    if (cs>=0)
    {
      if (str!=buf)
      {
        lstrcpyn(buf,str,sizeof(buf)-128);
        str=buf;
      }
      strcat(buf,cs>0 ? " checked" : " unchecked");
      
    }
    
    if (str && *str) return [(id)SWELL_CStringToCFString(str) autorelease];

  }
  if ([attribute isEqual:NSAccessibilityWindowAttribute])
  {
    HWND h = m_br->vwnd->GetRealParent();
    if (h)
    {
      return [(NSView *)h window];
    }
  }
  
  return nil;
}
- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute
{
  {
    const char *type = m_br->vwnd ?  m_br->vwnd->GetType() : NULL;
    if (!type) type="";
   // NSLog(@"accessibilityIsAttributeSettable: %@ %s %p\n",attribute,type,m_br->vwnd);
  }

  if ([attribute isEqual:NSAccessibilityFocusedAttribute]) return YES;
  return false;
}
- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute
{
  {
    const char *type = m_br->vwnd ?  m_br->vwnd->GetType() : NULL;
    if (!type) type="";
    //NSLog(@"accessibilitySetValue: %@ %s %p\n",attribute,type,m_br->vwnd);
  }

  if ([attribute isEqual:NSAccessibilityFocusedAttribute]) 
  {
    if ([value isKindOfClass:[NSNumber class]])
    {
      NSNumber *p = (NSNumber *)value;
      if ([p boolValue]) __focus = m_br->vwnd;
      else if (__focus == m_br->vwnd) __focus=NULL;
    }
  }
}

// parameterized attribute methods
- (NSArray *)accessibilityParameterizedAttributeNames
{
  {
    const char *type = m_br->vwnd ?  m_br->vwnd->GetType() : NULL;
    if (!type) type="";
    //NSLog(@"accessibilityParameterizedAttributeNames: %@ %s %p\n",@"",type,m_br->vwnd);
  }  
  return [NSArray arrayWithObjects:nil count:0];
  return nil;
}
- (id)accessibilityAttributeValue:(NSString *)attribute forParameter:(id)parameter
{
  {
    const char *type = m_br->vwnd ?  m_br->vwnd->GetType() : NULL;
    if (!type) type="";
    //NSLog(@"accessibilityAttributeValue: %@ %s %p\n",attribute,type,m_br->vwnd);
  }  
  return nil;
}

// action methods
- (NSArray *)accessibilityActionNames
{
  {
    const char *type = m_br->vwnd ?  m_br->vwnd->GetType() : NULL;
    if (!type) type="";
    //NSLog(@"accessibilityActionNames: %@ %s %p\n",@"",type,m_br->vwnd);
  }  
  NSString *s[32];
  int sidx=0;
  
  const char *type = m_br->vwnd ? m_br->vwnd->GetType() : NULL;
  if (type)
  {
    if (!strcmp(type,"vwnd_combobox") ||
        !strcmp(type,"vwnd_iconbutton") ||
        !strcmp(type,"vwnd_statictext") 
        ) s[sidx++] =  NSAccessibilityPressAction;
    
    if (!strcmp(type,"vwnd_slider")) 
    {
      s[sidx++] = NSAccessibilityDecrementAction;
      s[sidx++] = NSAccessibilityIncrementAction;
    }
  }
  
  return [NSArray arrayWithObjects:s count:sidx];
}
- (NSString *)accessibilityActionDescription:(NSString *)action
{
  {
    const char *type = m_br->vwnd ?  m_br->vwnd->GetType() : NULL;
    if (!type) type="";
    //NSLog(@"accessibilityActionDescription: %@ %s %p\n",action,type,m_br->vwnd);
  }  
  const char *type = m_br->vwnd ? m_br->vwnd->GetType() : NULL;
  if (type)
  {
    if ([action isEqual:NSAccessibilityPressAction])
    {
      if (!strcmp(type,"vwnd_combobox")) return @"Choose item";
      if (!strcmp(type,"vwnd_iconbutton")) return @"Press button";
      if (!strcmp(type,"vwnd_statictext")) return @"Doubleclick text";
    }
    else if (!strcmp(type,"vwnd_slider")) 
    {
      if ([action isEqual:NSAccessibilityDecrementAction]) return @"Decrease value of control";
      else if ([action isEqual:NSAccessibilityIncrementAction])return @"Increase value of control";
    }
  }
  return nil;
}

- (void)accessibilityPerformAction:(NSString *)action
{
  if (m_br->vwnd)
  {
    const char *type =  m_br->vwnd->GetType();
    if (!type) type="";
    
    if ([action isEqual:NSAccessibilityPressAction])
    {
      if (!strcmp(type,"vwnd_statictext")) m_br->vwnd->OnMouseDblClick(0,0);
      else
      {
        m_br->vwnd->OnMouseDown(0,0);
        m_br->vwnd->OnMouseUp(0,0);      
      }
    }
    else if ([action isEqual:NSAccessibilityDecrementAction])
    {
      m_br->vwnd->OnMouseWheel(0,0,-1);
    }
    else if ([action isEqual:NSAccessibilityIncrementAction])
    {
      m_br->vwnd->OnMouseWheel(0,0,1);
    }
    //NSLog(@"accessibilityPerformAction: %@ %s %p\n",action,type,m_br->vwnd);
  }  
  // todo
}

// Return YES if the UIElement doesn't show up to the outside world - i.e. its parent should return the UIElement's children as its own - cutting the UIElement out. E.g. NSControls are ignored when they are single-celled.
- (BOOL)accessibilityIsIgnored
{
  if (m_br->vwnd)
  {
    if (!m_br->vwnd->IsVisible()) return YES;
    if (m_br->vwnd->GetNumChildren()) 
    {
      const char *type = m_br->vwnd->GetType();
      if (type) if (!strcmp(type,"vwnd_unknown") || strstr(type,"container")) return YES;
    }
    else
    {
      RECT r;
      m_br->vwnd->GetPosition(&r);
      if (r.right <= r.left || r.bottom <= r.top) return YES;
    }
  }
  return NO;
}

// Returns the deepest descendant of the UIElement hierarchy that contains the point. You can assume the point has already been determined to lie within the receiver. Override this method to do deeper hit testing within a UIElement - e.g. a NSMatrix would test its cells. The point is bottom-left relative screen coordinates.
- (id)accessibilityHitTest:(NSPoint)point
{
  {
    const char *type = m_br->vwnd ?  m_br->vwnd->GetType() : NULL;
    if (!type) type="";
    //NSLog(@"accessibilityHitTest: %f,%f %s %p\n",point.x,point.y,type,m_br->vwnd);
  }  
  
  if (m_br->vwnd)
  {
    HWND h = m_br->vwnd->GetRealParent();
    if (h)
    {
      POINT pt = {(int)point.x,(int)point.y};
      ScreenToClient(h,&pt);
      WDL_VWnd *par = m_br->vwnd;
      while (par->GetParent()) par=par->GetParent();
      RECT r;
      par->GetPosition(&r);     
      WDL_VWnd *hit = par->VirtWndFromPoint(pt.x-r.left,pt.y-r.top);
      if (hit)
      {
        VWndNSAccessibility *a = GetVWndNSAccessible(hit);
        if (a) 
        {
          [a autorelease];
          return a;
        }
      }
    }
  }
  return nil;
}
// Returns the UI Element that has the focus. You can assume that the search for the focus has already been narrowed down to the reciever. Override this method to do a deeper search with a UIElement - e.g. a NSMatrix would determine if one of its cells has the focus.
- (id)accessibilityFocusedUIElement
{
  {
    const char *type = m_br->vwnd ?  m_br->vwnd->GetType() : NULL;
    if (!type) type="";
    //NSLog(@"accessibilityFocusedUIElement: %s %p\n",type,m_br->vwnd);
  }  
  if (__focus)
  {
    VWndNSAccessibility *a = GetVWndNSAccessible(__focus);
    if (a) return [a autorelease];
  }
  return self;
}


@end



static VWndNSAccessibility *GetVWndNSAccessible(WDL_VWnd *vwnd)
{
  if (!vwnd) return NULL;
  VWndBridgeNS *p = (VWndBridgeNS *)vwnd->GetAccessibilityBridge();
  if (p) 
  {
    if (p->par) [p->par retain];
    return p->par;
  }

  VWndNSAccessibility *ret = [[VWndNSAccessibility alloc] initWithVWnd:vwnd];
  [ret retain]; // caller will release, and the vwnd will own one reference too
  return ret;
}

LRESULT WDL_AccessibilityHandleForVWnd(bool isDialog, HWND hwnd, WDL_VWnd *vw, WPARAM wParam, LPARAM lParam)
{
  if (vw && lParam && wParam==0x1001)
  {
    VWndNSAccessibility *nsa = GetVWndNSAccessible(vw);
    if (nsa) *(id *)lParam = nsa;
  }
  return 0;
}