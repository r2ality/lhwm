#include <X11/Xlib.h>
#include <X11/XKBlib.h>
#include <X11/Xatom.h>
#include <X11/cursorfont.h>
#include <X11/XF86keysym.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>
#include <X11/extensions/Xinerama.h>
#include <X11/extensions/Xrandr.h>
#include <X11/extensions/Xcomposite.h>
#include <X11/extensions/Xrender.h>
#include <stddef.h>
#include <stdio.h>
#include <sys/select.h>
#include <time.h>
#include <signal.h>

#define O(s,f) printf("%s.%s %zu\n", #s, #f, offsetof(s, f))
#define S(s)   printf("sizeof.%s %zu\n", #s, sizeof(s))
#define C(c)   printf("%s %ld\n", #c, (long)(c))

int main(void) {
    S(XEvent);
    O(XKeyEvent, serial); O(XKeyEvent, send_event); O(XKeyEvent, display);
    O(XKeyEvent, window); O(XKeyEvent, root); O(XKeyEvent, subwindow);
    O(XKeyEvent, time); O(XKeyEvent, x); O(XKeyEvent, y);
    O(XKeyEvent, x_root); O(XKeyEvent, y_root); O(XKeyEvent, state);
    O(XKeyEvent, keycode); O(XKeyEvent, same_screen); S(XKeyEvent);
    O(XButtonEvent, button); O(XButtonEvent, x_root); O(XButtonEvent, state);
    O(XButtonEvent, subwindow); O(XButtonEvent, window);
    O(XMotionEvent, x_root); O(XMotionEvent, y_root);
    O(XCrossingEvent, window); O(XCrossingEvent, mode);
    O(XExposeEvent, window); O(XExposeEvent, count);
    O(XMapRequestEvent, window); O(XMapRequestEvent, parent);
    O(XMapEvent, window); O(XMapEvent, override_redirect);
    O(XUnmapEvent, window); O(XUnmapEvent, send_event); O(XUnmapEvent, from_configure);
    O(XDestroyWindowEvent, window);
    O(XReparentEvent, window); O(XReparentEvent, parent);
    O(XConfigureEvent, window);
    O(XConfigureRequestEvent, window); O(XConfigureRequestEvent, x);
    O(XConfigureRequestEvent, y); O(XConfigureRequestEvent, width);
    O(XConfigureRequestEvent, height); O(XConfigureRequestEvent, border_width);
    O(XConfigureRequestEvent, above); O(XConfigureRequestEvent, detail);
    O(XConfigureRequestEvent, value_mask);
    O(XPropertyEvent, window); O(XPropertyEvent, atom);
    O(XClientMessageEvent, window); O(XClientMessageEvent, message_type);
    O(XClientMessageEvent, format); O(XClientMessageEvent, data);
    S(XClientMessageEvent);
    O(XSelectionClearEvent, window); O(XSelectionClearEvent, selection);
    O(XErrorEvent, resourceid); O(XErrorEvent, error_code);

    O(XWindowAttributes, x); O(XWindowAttributes, y);
    O(XWindowAttributes, width); O(XWindowAttributes, height);
    O(XWindowAttributes, border_width); O(XWindowAttributes, depth);
    O(XWindowAttributes, visual); O(XWindowAttributes, root);
    O(XWindowAttributes, class); O(XWindowAttributes, map_state);
    O(XWindowAttributes, override_redirect); S(XWindowAttributes);

    O(XSetWindowAttributes, background_pixel);
    O(XSetWindowAttributes, event_mask);
    O(XSetWindowAttributes, override_redirect); S(XSetWindowAttributes);

    O(XWindowChanges, x); O(XWindowChanges, y); O(XWindowChanges, width);
    O(XWindowChanges, height); O(XWindowChanges, border_width);
    O(XWindowChanges, sibling); O(XWindowChanges, stack_mode); S(XWindowChanges);

    O(XClassHint, res_name); O(XClassHint, res_class);
    O(XTextProperty, value); O(XTextProperty, encoding);
    O(XTextProperty, format); O(XTextProperty, nitems); S(XTextProperty);
    O(XModifierKeymap, max_keypermod); O(XModifierKeymap, modifiermap);
    O(XFontStruct, fid);
    S(XGCValues);

    O(XineramaScreenInfo, screen_number); O(XineramaScreenInfo, x_org);
    O(XineramaScreenInfo, y_org); O(XineramaScreenInfo, width);
    O(XineramaScreenInfo, height); S(XineramaScreenInfo);

    O(XRRScreenResources, ncrtc); O(XRRScreenResources, crtcs);
    O(XRRScreenResources, noutput); O(XRRScreenResources, outputs);
    O(XRRScreenResources, nmode); O(XRRScreenResources, modes);
    S(XRRScreenResources);
    O(XRRModeInfo, id); O(XRRModeInfo, width); O(XRRModeInfo, height);
    S(XRRModeInfo);
    O(XRRCrtcInfo, x); O(XRRCrtcInfo, y); O(XRRCrtcInfo, width);
    O(XRRCrtcInfo, height); O(XRRCrtcInfo, mode); O(XRRCrtcInfo, noutput);
    O(XRRCrtcInfo, outputs); S(XRRCrtcInfo);
    O(XRROutputInfo, crtc); O(XRROutputInfo, connection); O(XRROutputInfo, ncrtc);
    O(XRROutputInfo, crtcs); O(XRROutputInfo, nmode); O(XRROutputInfo, npreferred);
    O(XRROutputInfo, modes); S(XRROutputInfo);

    S(XTransform);
    S(XRenderPictureAttributes);

    S(fd_set);
    S(struct timespec); S(struct timeval);
    O(struct tm, tm_sec); O(struct tm, tm_min); O(struct tm, tm_hour);

    /* ---- constants ---- */
    C(Mod4Mask); C(Mod1Mask); C(ShiftMask); C(ControlMask); C(LockMask);
    C(Button1); C(Button3); C(Button4); C(Button5);
    C(KeyPress); C(ButtonPress); C(ButtonRelease); C(MotionNotify);
    C(EnterNotify); C(Expose); C(MapRequest); C(MapNotify);
    C(DestroyNotify); C(UnmapNotify); C(ReparentNotify); C(ConfigureNotify);
    C(SelectionClear); C(PropertyNotify); C(ClientMessage); C(ConfigureRequest);
    C(NoEventMask); C(KeyPressMask); C(ButtonPressMask); C(ButtonReleaseMask);
    C(EnterWindowMask); C(PointerMotionMask); C(ExposureMask);
    C(StructureNotifyMask); C(SubstructureNotifyMask); C(SubstructureRedirectMask);
    C(PropertyChangeMask);
    C(GrabModeAsync); C(GrabSuccess); C(RevertToPointerRoot);
    C(CurrentTime); C(None); C(AnyKey); C(AnyModifier); C(Success);
    C(PropModeReplace);
    C(XA_CARDINAL); C(XA_ATOM); C(XA_WINDOW); C(XA_WM_NAME);
    C(IsUnmapped); C(IsViewable);
    C(InputOutput); C(CopyFromParent);
    C(CWBackPixel); C(CWOverrideRedirect); C(CWEventMask);
    C(NotifyNormal);
    C(XC_left_ptr); C(XC_fleur); C(XC_bottom_right_corner);
    C(XK_space); C(XK_Return); C(XK_Escape); C(XK_Page_Up); C(XK_Page_Down);
    C(XK_Left); C(XK_Right); C(XK_Up); C(XK_Down); C(XK_Tab); C(XK_BackSpace);
    C(XK_KP_Enter); C(XK_KP_Left); C(XK_KP_Right); C(XK_KP_Up); C(XK_KP_Down);
    C(XK_Num_Lock); C(XK_Print); C(XK_Sys_Req);
    C(XK_1); C(XK_9); C(XK_q); C(XK_z); C(XK_Z); C(XK_h); C(XK_j); C(XK_k); C(XK_l);
    C(XF86XK_AudioRaiseVolume); C(XF86XK_AudioLowerVolume); C(XF86XK_AudioMute);
    C(XF86XK_AudioPlay); C(XF86XK_AudioPause); C(XF86XK_AudioNext);
    C(XF86XK_AudioPrev); C(XF86XK_AudioStop);
    C(XF86XK_MonBrightnessUp); C(XF86XK_MonBrightnessDown);
    C(NoSymbol);
    C(RRScreenChangeNotifyMask); C(RRScreenChangeNotify); C(RR_Connected);
    C(RR_Rotate_0); C(RRSetConfigSuccess);
    C(CompositeRedirectAutomatic);
    C(PictOpSrc);
    C(SIGCHLD); C(SIGTERM); C(SIGKILL);
    C(CLOCK_REALTIME);
    printf("SIG_IGN %ld\n", (long)SIG_IGN);
    printf("FilterBilinear %s\n", FilterBilinear);
    return 0;
}
