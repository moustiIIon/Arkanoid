# Le son sur GB, comment le gerer


Le Game Boy ne joue pas de fichiers audio. Il **génère le son en temps réel** via un chip dédié intégré au CPU Sharp LR35902 : l'**APU** (Audio Processing Unit).

Le principe est simple : on écrit des valeurs dans des **registres hardware** (des adresses mémoire spéciales), et le hardware produit le signal électrique directement envoyé au haut-parleur.

---

## Les 4 canaux

L'APU dispose de 4 canaux indépendants, chacun produisant un type de son différent.


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
