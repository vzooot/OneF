# App Store submission kit

Everything to paste into App Store Connect. Screenshots in this folder are
already at the required 6.9" size (1320×2868).

## App information

| Field | Value |
|---|---|
| Name | **OneF** |
| Subtitle | Race countdowns & standings |
| Bundle ID | `com.woqomoqo.OneF` |
| SKU | `onef-ios-001` |
| Primary category | Sports |
| Secondary category | News |
| Price | Free |
| Age rating | 4+ (answer "No" to everything) |

Note: the name and subtitle deliberately avoid "F1" and "Formula 1"
(trademarks). The description may reference the sport factually.

## Promotional text (170 chars max)

> Never miss lights out. Live countdowns to every session, a 3D circuit map,
> full results and standings, paddock news, and Lock Screen widgets.

## Description

> OneF is a fast, beautiful companion app for motorsport race weekends.
>
> COUNTDOWN
> • Live countdown to every session of the upcoming race weekend — practice,
>   qualifying, sprint, and race
> • Start-light gantry that fills up as race week approaches
> • Full weekend timetable in your local timezone
> • Broadcast-style session clock with milliseconds while a session is live
>
> THE CIRCUIT IN 3D
> • Real track shapes rendered in interactive 3D — rotate, zoom, explore
> • Corner markers, track length, direction, and pit-lane time loss
>
> RESULTS & STANDINGS
> • Podium and full classification for every completed round of the season
> • Qualifying results with Q1/Q2/Q3 times
> • Complete drivers' and constructors' championship standings
>
> ALWAYS ON YOUR LOCK SCREEN
> • Lock Screen and Home Screen widgets with self-updating countdowns
> • Pin a session as a Live Activity: a ticking countdown in the Dynamic
>   Island that flips to LIVE at green light
> • Optional alerts 15 minutes before every session
>
> PADDOCK NEWS
> • The latest stories from major motorsport outlets, in one feed
>
> OneF is free, collects no data, and requires no account.
>
> OneF is an independent fan app. It is not affiliated with, endorsed by, or
> associated with Formula 1, Formula One Group, the FIA, or any team. Race
> data is provided by community-maintained public sources.

## Keywords (100 chars max)

```
race,countdown,grand prix,motorsport,standings,results,circuit,track,session,widget,live,formula
```

## URLs

| Field | Value |
|---|---|
| Support URL | https://github.com/vzooot/OneF |
| Marketing URL | (optional, leave empty) |
| Privacy Policy URL | https://github.com/vzooot/OneF/blob/main/PRIVACY.md |

## App Privacy (questionnaire)

- Data collection: **Data Not Collected** (the app has no analytics, no
  accounts, no tracking; all requests go directly to public data APIs).

## App Review notes (paste into the "Notes" field)

> OneF is an unofficial, free fan companion app for motorsport. It is not
> affiliated with Formula 1 and does not use any official F1 branding, logos,
> or media. All data comes from public community APIs (Jolpica F1, licensed
> CC BY-NC-SA with attribution shown in the app's About screen) and public
> RSS headlines that link to the original publishers. The app shows a
> prominent non-affiliation disclaimer in its About screen (tap ⓘ on the
> first tab). No login is required; all features are available immediately.

## Build & upload checklist

1. Use a **release (non-beta) Xcode** — App Store binaries can't be built
   with beta toolchains.
2. Open the project, select the "OneF" scheme, destination "Any iOS Device".
3. Product → Archive, then Organizer → Distribute App → App Store Connect.
4. In App Store Connect: create the app record (bundle ID
   `com.woqomoqo.OneF` appears after the first upload or can be registered
   via Certificates, Identifiers & Profiles), attach the build, paste the
   text above, upload screenshots, submit.
5. Optional but recommended: a TestFlight round on your own phone first —
   especially to try the widgets, Live Activity, and notifications on device.
