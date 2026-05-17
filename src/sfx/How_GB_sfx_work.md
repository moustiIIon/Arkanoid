# Le son sur GB, comment le gerer


Le Game Boy ne joue pas de fichiers audio. Il **génère le son en temps réel** via un chip dédié intégré au CPU Sharp LR35902 : l'**APU** (Audio Processing Unit)

Le principe est simple : on écrit des valeurs dans des **registres hardware** (des adresses mémoire spéciales), et le hardware produit le signal électrique directement envoyé au haut-parleur

---

## Les 4 canaux

L'APU dispose de 4 canaux indépendants, chacun produisant un type de son différent


Le sweep : cela permet de modifier la frequence automatiquement apres son lancement, cela permet de ne pas avoir un son fixe et monotone

| Canal | Type | Particularité |
|---|---|---|
| Canal 1 | Onde carrée | Sweep automatique de fréquence |
| Canal 2 | Onde carrée | Simple, sans sweep |
| Canal 3 | Wave custom | 32 samples 4-bit personnalisables |
| Canal 4 | Bruit blanc | Percussions, explosions |

---

## Activer l'APU

Avant tout, il faut allumer le système audio via le registre **NR52** (`$FF26`).  
Si ce bit est à 0, tous les autres registres sont ignorés.

```gbz80
ld a, $80
ldh [rNR52], a    ; bit 7 = 1 → APU ON

ld a, $77
ldh [rNR50], a    ; volume max gauche + droite

ld a, $FF
ldh [rNR51], a    ; activer tous les canaux sur les deux sorties
```

---

## Anatomie d'un son, Canal 1 (onde carrée + sweep)

Chaque canal est contrôlé par 4 ou 5 registres. Voici le canal 1 :

### NR10, Sweep (`$FF10`)
Permet de modifier automatiquement la fréquence après le déclenchement

```
Bits 6-4 : période du sweep (0 = désactivé)
Bit  3   : direction (0 = monte, 1 = descend)
Bits 2-0 : vitesse du changement
```

### NR11, Duty + Longueur (`$FF11`)
```
Bits 7-6 : forme de l'onde carrée
           00 = 12.5%  _-------
           01 = 25%    __------
           10 = 50%    ____----  (le plus naturel)
           11 = 75%    ______--
Bits 5-0 : durée du son (si activée dans NR14)
```

### NR12, Volume + Envelope (`$FF12`)
```
Bits 7-4 : volume initial (0 = silence, 15 = max)
Bit  3   : direction envelope (0 = descend, 1 = monte)
Bits 2-0 : vitesse envelope (0 = pas de changement, 7 = très rapide)
```

### NR13, Fréquence basse (`$FF13`)
Les 8 bits bas de la fréquence (11 bits au total).

### NR14, Fréquence haute + Trigger (`$FF14`)
```
Bit  7   : TRIGGER - déclenche le son (écrire 1 pour jouer)
Bit  6   : utiliser la durée de NR11 (1) ou jouer indéfiniment (0)
Bits 2-0 : les 3 bits hauts de la fréquence
```

---

## Calcul de la fréquence

La fréquence n'est pas en Hz directement. La formule est :

```
Valeur registre = 2048 - (131072 / fréquence_Hz)
```

Exemples de notes musicales :

| Note | Fréquence Hz | Valeur registre |
|---|---|---|
| La 4 (A4) | 440 Hz | $75C |
| Do 5 (C5) | 523 Hz | $793 |
| Sol 5 (G5) | 784 Hz | $7C1 |

Les 8 bits bas vont dans NR13, les 3 bits hauts dans NR14 (bits 2-0).

```gbz80
; Jouer La 4 (440 Hz) → valeur $75C
ld a, $5C
ldh [rNR13], a    ; bits bas
ld a, $87         ; trigger (bit 7) + $07 (bits hauts de $75C)
ldh [rNR14], a
```

---

## L'Envelope, volume dynamique

L'envelope permet au son de **monter ou descendre en volume automatiquement** sans intervention du CPU. C'est ce qui donne le côté "naturel" aux sons

```
NR12 = $F3
        ↑↑
        F = volume initial 15 (max)
         3 = descend rapidement
```

Un son avec envelope descendante s'éteint tout seul, pas besoin de le couper manuellement

---

## Le Canal 4 - Bruit blanc

Utile pour les percussions et explosions. Pas de fréquence musicale - il génère du bruit aléatoire

```gbz80
ld a, $FF
ldh [rNR41], a    ; longueur max
ld a, $F1
ldh [rNR42], a    ; volume + envelope
ld a, $57
ldh [rNR43], a    ; paramètres du bruit
ld a, $80
ldh [rNR44], a    ; trigger
```

---

## Ordre d'écriture des registres

L'ordre est important. Il faut toujours écrire dans cet ordre :

1. NR10 (sweep, canal 1 uniquement)
2. NR11 (duty + longueur)
3. NR12 (volume + envelope)
4. NR13 (fréquence basse)
5. NR14 (fréquence haute + **trigger en dernier**)

Le trigger doit toujours être le **dernier registre écrit**, c'est lui qui déclenche la lecture avec tous les paramètres précédents

---

## Résumé

```
APU ON (NR52)
    └── Canal 1 (NR10-NR14) : mélodie + SFX avec sweep
    └── Canal 2 (NR21-NR24) : mélodie / harmonie
    └── Canal 3 (NR30-NR34) : sons custom 32 samples
    └── Canal 4 (NR41-NR44) : percussions / bruit
```

Le son sur Game Boy est entièrement **procédural**, pas de samples, pas de fichiers, juste des mathématiques et des registres hardware
