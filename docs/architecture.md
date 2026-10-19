# البنية الهندسية للمرحلة الثالثة: منظومة الألعاب المتعددة في الغرفة المشتركة (Multiplayer Suite Architecture)

## 1. الهيكل العام للتزامن متعدد الأنماط

```mermaid
graph TD
    subgraph ActiveOnlineRoomScreen [شاشة الغرفة النشطة الموحدة]
        Header[شريط الحضور المزدوج + مبدل الأنماط OnlineGameMode]
        Overlay[طبقة التفاعلات العائمة FloatingReactionsLayer]
        
        subgraph Mode_Cards [نمط 1: بطاقات الحوار]
            CardSync[مزامنة البطاقات والأدوار]
        end

        subgraph Mode_KnowMe [نمط 2: قد إيش تعرفني؟]
            KM_Secret[الإدخال السري]
            KM_Guess[حقل التخمين]
            KM_Reveal[المقارنة والكشف والنقاط]
        end

        subgraph Mode_GuessWho [نمط 3: خمن الشخصية]
            GW_Pick[الاختيار السري للشخصية]
            GW_Board[لوحة الـ24 شخصية والاستبعاد]
            GW_QA[حوار نعم/لا والتخمين النهائي]
        end
    end

    subgraph Supabase_Realtime [قنوات البث المباشر WebSocket]
        RT_Presence[حضور الطرفين Presence]
        RT_Reactions[بث الإيموجي reaction]
        RT_Mode[بث تبديل النمط game_mode_change]
        RT_KnowMe[بث أحداث know_me_*]
        RT_GuessWho[بث أحداث guess_who_*]
    end

    Header --> RT_Mode
    Overlay --> RT_Reactions
    Mode_Cards --> RT_Presence
    Mode_KnowMe --> RT_KnowMe
    Mode_GuessWho --> RT_GuessWho
```

## 2. بروتوكول البث الفوري عبر WebSocket (Realtime Broadcast Protocol)

جميع أحداث الألعاب تعمل عبر `channel.sendBroadcastMessage` و `channel.onBroadcast` دون الحاجة لكتابة أحداث عابرة في قاعدة بيانات PostgreSQL:

| الحدث (`event`) | المعاملات (`payload`) | الوصف |
|---|---|---|
| `game_mode_change` | `{ mode: 'cards' \| 'knowMe' \| 'guessWho' }` | تبديل اللعبة الحالية في الغرفة لكلا الشريكين |
| `reaction` | `{ emoji, sender_role, timestamp }` | الإيموجي العائم المشترك |
| `know_me_step` | `{ step: 0 \| 1 \| 2, question_id, answering_role, secret_preview?, guess?, match? }` | مزامنة خطوات لعبة قد إيش تعرفني |
| `guess_who_action` | `{ action: 'pick_ready' \| 'ask' \| 'answer' \| 'guess' \| 'restart', role, data }` | مزامنة أدوار وأسئلة واستبعاد خمن الشخصية |

## 3. معايير الأمان والخصوصية (Privacy & Zero-Cheating)
- **في «خمن الشخصية»:** معرف الشخصية السرية لا يُرسل عبر الشبكة حتى لحظة التخمين النهائي أو إعلان الفوز.
- **في «قد إيش تعرفني؟»:** إشعار اكتمال الإجابة السرية يُرسل أولاً، ثم تُكشف الإجابتان معاً عند إرسال التخمين.
- **الصمود بدون اتصال:** في حال فقدان الاتصال، تحتفظ الواجهات بالحالة المحلية وتعرض مؤشر إعادة الاتصال المباشر.

---

# البنية الهندسية للمرحلة الرابعة: ربط الشريك الدائم ونمط الحياة الزوجية (Phase 4 Architecture)

## 1. نموذج الدعوة المباشرة بضغطة واحدة (1-Click Partner Invitations)

```mermaid
sequenceDiagram
    autonumber
    actor PlayerA as الشريك (المضيف)
    participant ChannelA as قناة الدعوات السحابية
    participant ChannelB as قناة استماع الشريك
    actor PlayerB as الشريك (المستلم)

    PlayerA->>PlayerA: ينقر «إنشاء غرفة» أو «دعوة مباشرة»
    PlayerA->>ChannelA: بث مباشر لحدث room_invite على قناة invites_{partnerEmail}
    ChannelA->>ChannelB: تسليم الحدث عبر Supabase Realtime WebSocket
    ChannelB->>PlayerB: إشعار فوري ونافذة منبثقة «دعوة للعب من أحمد!»
    PlayerB->>PlayerB: يضغط «قبول والانضمام فوراً 🎮»
    PlayerB->>PlayerA: انضمام فوري للغرفة بدون كتابة أي رمز سداسي
```

## 2. جدول أحداث الدعوات المباشرة
| القناة | الحدث | البيانات (`payload`) | التأثير في الواجهة |
|---|---|---|---|
| `invites_{userIdentifier}` | `room_invite` | `{ room_id, room_code, host_name, timestamp }` | إظهار نافذة قبول فورية والانتقال للغرفة النشطة مباشرة |

