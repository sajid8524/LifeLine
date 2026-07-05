#  LifeSaver DTN
### *Emergency Communication When Traditional Communication Fails*

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Android](https://img.shields.io/badge/Android-34A853?style=for-the-badge&logo=android&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![Gemini](https://img.shields.io/badge/Gemini_AI-4285F4?style=for-the-badge&logo=google&logoColor=white)

**GDG WOWFest Hackathon 2026 Submission**

*"When every signal dies, one signal must survive."*

</div>

---

#  Problem Statement

During disasters such as floods, earthquakes, train accidents, and building collapses, communication infrastructure is often the first system to fail.

Traditional communication methods like:

- Mobile Networks
- SMS
- WhatsApp
- Internet Services

become unavailable, leaving victims unable to communicate with rescue teams.

LifeSaver DTN solves this problem by enabling **offline emergency communication using device-to-device networking**, without relying on cellular towers or internet connectivity.

---

#  Solution

LifeSaver DTN is an **offline-first emergency communication platform** that enables:

- Emergency SOS generation
- Device-to-device communication
- Store-Carry-Forward networking
- Delay Tolerant Networking (DTN)
- Emergency message relay
- Rescue node synchronization

using Google's Nearby Connections API.

---

#  Features

##  Emergency SOS Creation
- Create emergency alerts
- Add victim count
- Include GPS location
- Add emergency description

---

##  Offline Communication
- Works without:
  - Internet
  - Mobile Data
  - SIM Network

Uses:

- Bluetooth
- BLE
- WiFi Direct
- Google Nearby Connections API

---

##  Local Emergency Storage
- SQLite local database
- Emergency history
- Device cache
- Relay queue

---

##  Store-Carry-Forward
Implements Delay Tolerant Networking principles:

```text
Receive
    ↓
Store
    ↓
Carry
    ↓
Forward
```

---

##  Rescue Node Mode
Special rescue devices can:

- Collect emergency packets
- Synchronize emergencies
- Coordinate rescue operations

---

##  Emergency Priority Classification
Emergency severity classification:

- Critical
- High
- Medium
- Low

---

#  System Architecture

```text
                    Google Cloud
               (Future Integration)
                       ▲
                       │
                 Rescue Node
                       ▲
                       │
               Store-Carry-Forward
                       ▲
                       │
Volunteer ◄──► Victim ◄──► Volunteer
                       │
                       ▼
                    SQLite
```

---

#  Tech Stack

| Category | Technology |
|----------|------------|
| Frontend | Flutter |
| Language | Dart |
| Communication | Google Nearby Connections API |
| Local Database | SQLite |
| Networking | Delay Tolerant Networking |
| AI | Gemini API |
| Cloud | Firebase |
| Maps | Google Maps API |
| Version Control | Git & GitHub |

---

#  Application Screens

- Splash Screen
- Home Dashboard
- SOS Creation
- Emergency Preview
- Device Discovery
- Emergency Inbox
- Message Details
- Rescue Node Mode
- Settings

---
![LifeLine Screenshot](WhatsApp%20Image%202026-07-05%20at%204.38.51%20AM.jpeg)
#  Demo Workflow

```text
Victim
   ↓
Create SOS
   ↓
Nearby Device
   ↓
Store Emergency
   ↓
Relay Emergency
   ↓
Rescue Node
   ↓
Cloud Synchronization
```

---

#  Technical Innovation

LifeSaver DTN demonstrates:

 Offline-first architecture

 Delay Tolerant Networking

 Store-Carry-Forward routing

 Opportunistic networking

 Infrastructure-independent communication

---

#  Real World Applications

- Floods
- Earthquakes
- Train Accidents
- Cyclones
- Building Collapses
- Remote Areas
- Search & Rescue Missions

---

#  Future Scope

- Firebase Synchronization
- Google Maps Integration
- Gemini AI Prioritization
- Rescue Command Dashboard
- Drone-based Relays
- Satellite Communication
- Emergency Vehicle Integration

---


```

---



#  APK

Download APK:

```text
https://drive.google.com/drive/folders/13qx6oUShtw_yCRRxk60S306xtjuDq2ey?usp=sharing
```

---

#  Team

##

- Saraswathi Reddy
- Sajid Ali
- Lalitha velpuru
- Sai Ram

---

#  Hackathon Submission

**Event:** GDG WOWFest Hackathon 2026



---

#  Our Mission

> **"When communication infrastructure fails, survival should not depend on signal strength."**
