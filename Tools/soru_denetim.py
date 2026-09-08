#!/usr/bin/env python3
# Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
# -*- coding: utf-8 -*-
"""HMGS Koçu — Soru Onay Kapısı.

Hiçbir soru bu denetimden geçmeden `Resources/seed_questions.json` dosyasına
girmez. Amaç, insan gözünün kaçırabileceği yapısal hataları makineye yakalatmak;
hukuki doğruluğu değil (onu protokolün 24.1-24.5 adımları ve insan incelemesi
sağlar), ama hukuki doğruluğun ÖNKOŞULU olan biçimsel bütünlüğü.

Kullanım:
    python3 Tools/soru_denetim.py Resources/seed_questions.json
        → mevcut havuzu "taban" ölçütleriyle denetler

    python3 Tools/soru_denetim.py Resources/seed_questions.json yeni_parti.json
        → yeni partiyi TAM standartla, birleşimi taban ölçütleriyle denetler

Çıkış kodu 0 = geçti, 1 = kalın yazılı hata var (soru eklenmez).
"""
import json, re, sys, collections, os

# ── Geçerli değerler (uygulamadaki LegalSubject ve Difficulty ile birebir) ──
SUBJECTS = {
    "medeni_hukuk", "borclar_hukuku", "ticaret_hukuku", "anayasa_hukuku",
    "anayasa_yargisi", "idare_hukuku", "idari_yargilama_usulu", "ceza_hukuku",
    "ceza_muhakemesi_hukuku", "medeni_usul_hukuku", "icra_iflas_hukuku",
    "is_hukuku", "uluslararasi_ozel_hukuk", "uluslararasi_kamu_hukuku",
    "vergi_hukuku", "vergi_usul_hukuku", "hukuk_felsefesi_sosyolojisi",
    "turk_hukuk_tarihi", "genel_kamu_hukuku", "meslek_hukuku_etik",
    "avrupa_birligi_hukuku", "insan_haklari_hukuku", "fikri_sinai_haklar",
    "adli_bilisim",
}
DIFFICULTIES = {"kolay", "orta", "zor"}

# ── Eşikler ──
# TABAN: tüm havuzun (eski içerik dahil) asla altına düşmemesi gereken sınır.
TABAN = dict(expl_min=40, expl_max=1200, prompt_max=400, opt_max=400,
             tag_min=3, tag_max=60, correct_longest_max=0.75,
             negative_stem_max=0.15, same_ref_max=10)
# TAM: yeni üretilen her partinin karşılaması gereken gerçek standart.
TAM = dict(expl_min=380, expl_max=900, prompt_max=350, opt_max=300,
           tag_min=4, tag_max=45, correct_longest_max=0.40,
           negative_stem_max=0.20, same_ref_max=4)

REF_MADDE = re.compile(r'\bm\.\s*\d+')
REF_BICIM = re.compile(r'^[0-9A-Za-zÇĞİÖŞÜçğıöşü\.\s\-\(\)]+ m\.\s*\d+')
NEGATIF = re.compile(r'(DEĞİLDİR|OLUŞTURMAZ|YANLIŞTIR|OLAMAZ|SAYILMAZ)')
YASAK_SIK = re.compile(r'^\s*(hiçbiri|hepsi|yukarıdakilerin (hepsi|hiçbiri))\s*$', re.I)


def denetle(sorular, esik, etiket, havuz_disi_promptlar=None, havuz_disi_idler=None):
    hata, uyari = [], []
    idler = collections.Counter(q.get('id') for q in sorular)
    promptlar = collections.Counter(q.get('prompt', '').strip() for q in sorular)

    for q in sorular:
        yer = f"[{q.get('subject','?')}/{q.get('topicTag','?')}]"

        # — zorunlu alanlar ve tipler —
        for alan in ('id', 'subject', 'difficulty', 'topicTag', 'prompt',
                     'options', 'correctOptionIndex', 'explanation'):
            if alan not in q:
                hata.append(f"{yer} '{alan}' alanı yok"); continue
        if q.get('subject') not in SUBJECTS:
            hata.append(f"{yer} geçersiz ders adı: {q.get('subject')!r}")
        if q.get('difficulty') not in DIFFICULTIES:
            hata.append(f"{yer} geçersiz zorluk: {q.get('difficulty')!r}")

        # — şıklar —
        opts = q.get('options', [])
        if len(opts) != 5:
            hata.append(f"{yer} şık sayısı 5 değil ({len(opts)})")
        else:
            if len({o.strip().lower() for o in opts}) != 5:
                hata.append(f"{yer} aynı şık iki kez var")
            if any(not o.strip() for o in opts):
                hata.append(f"{yer} boş şık var")
            for o in opts:
                if YASAK_SIK.match(o):
                    hata.append(f"{yer} yasak şık: {o!r}")
                if len(o) > esik['opt_max']:
                    uyari.append(f"{yer} şık çok uzun ({len(o)} > {esik['opt_max']})")
            if not (0 <= q.get('correctOptionIndex', -1) < 5):
                hata.append(f"{yer} correctOptionIndex geçersiz")

        # — metin ölçüleri —
        if len(q.get('prompt', '')) > esik['prompt_max']:
            uyari.append(f"{yer} soru kökü uzun ({len(q['prompt'])})")
        e = len(q.get('explanation', ''))
        if e < esik['expl_min']:
            hata.append(f"{yer} açıklama çok kısa ({e} < {esik['expl_min']})")
        if e > esik['expl_max']:
            uyari.append(f"{yer} açıklama çok uzun ({e})")
        if q.get('explanation') and len(q.get('prompt', '')) >= e:
            uyari.append(f"{yer} açıklama soru kökünden kısa — öğretmiyor olabilir")
        t = len(q.get('topicTag', ''))
        if not (esik['tag_min'] <= t <= esik['tag_max']):
            uyari.append(f"{yer} topicTag uzunluğu sınır dışı ({t})")

        # — dayanak —
        ref = (q.get('lawReference') or '').strip()
        if not ref:
            hata.append(f"{yer} lawReference boş — dayanaksız soru kabul edilmez")
        elif not REF_BICIM.match(ref) and 'doktrin' not in ref.lower():
            uyari.append(f"{yer} lawReference biçimi alışılmadık: {ref!r}")
        if ref and REF_MADDE.search(ref) and not REF_MADDE.search(q.get('explanation', '')):
            uyari.append(f"{yer} açıklamada madde numarası geçmiyor")

        # — çıkmış soru iddiası —
        if q.get('isVerifiedPastExamQuestion'):
            hata.append(f"{yer} 'çıkmış soru' olarak işaretlenmiş — buna izin yok")
        if q.get('examYear') is not None:
            hata.append(f"{yer} examYear dolu — buna izin yok")

        # — havuzla çakışma —
        if havuz_disi_idler and q.get('id') in havuz_disi_idler:
            hata.append(f"{yer} id mevcut havuzda zaten var")
        if havuz_disi_promptlar and q.get('prompt', '').strip() in havuz_disi_promptlar:
            hata.append(f"{yer} soru metni mevcut havuzda zaten var")

    for i, n in idler.items():
        if n > 1: hata.append(f"id tekrarı ({n} kez): {i}")
    for p, n in promptlar.items():
        if n > 1: hata.append(f"soru metni tekrarı ({n} kez): {p[:70]}…")

    # ── küme düzeyi ölçütler ──
    # Bozuk kayıtlar (5 şıkkı olmayan, indeksi sınır dışı) burada hesaba
    # KATILMAZ: yukarıda zaten hata olarak raporlandılar ve toplu istatistiği
    # çökertmemeleri gerekir. (Bu koruma, geçersiz indeksli bir test kaydının
    # betiği IndexError ile düşürmesi üzerine eklendi.)
    def saglam(q):
        opts = q.get('options')
        idx = q.get('correctOptionIndex')
        return isinstance(opts, list) and len(opts) == 5 and isinstance(idx, int) and 0 <= idx < 5

    n = len(sorular)
    saglamlar = [q for q in sorular if saglam(q)]
    if saglamlar:
        en_uzun_dogru = sum(1 for q in saglamlar
                            if len(q['options'][q['correctOptionIndex']]) == max(len(o) for o in q['options']))
        oran = en_uzun_dogru / len(saglamlar)
        # Doğru cevabın sistematik olarak en uzun şık olması, soruyu okumadan
        # tahmin edilebilir hale getirir. Rastgele dağılımda beklenen ~%20.
        mesaj = (f"doğru şık en uzun olan: {en_uzun_dogru}/{len(saglamlar)} (%{100*oran:.1f}; "
                 f"sınır %{100*esik['correct_longest_max']:.0f}, rastgelede %20)")
        if oran > esik['correct_longest_max']:
            hata.append(mesaj)
        elif oran > 0.30:
            uyari.append(mesaj)

        neg = sum(1 for q in sorular if NEGATIF.search(q.get('prompt', '')))
        if n and neg / n > esik['negative_stem_max']:
            uyari.append(f"olumsuz köklü soru oranı yüksek: %{100*neg/n:.1f}")

        refs = collections.Counter(q.get('lawReference') for q in sorular)
        for r, c in refs.items():
            if c > esik['same_ref_max']:
                uyari.append(f"aynı dayanaktan çok soru: {r} ({c} soru)")

        dist = collections.Counter(q.get('correctOptionIndex') for q in saglamlar)
        for i in range(5):
            p = dist.get(i, 0) / len(saglamlar)
            if len(saglamlar) >= 40 and not (0.10 < p < 0.32):
                uyari.append(f"{'ABCDE'[i]} şıkkı dengesiz doğru: %{100*p:.1f}")

    print(f"\n── {etiket} ({n} soru) ──")
    if hata:
        print(f"  ✗ {len(hata)} HATA")
        for h in hata[:40]: print("     -", h)
        if len(hata) > 40: print(f"     … ve {len(hata)-40} tane daha")
    else:
        print("  ✓ hata yok")
    if uyari:
        print(f"  ! {len(uyari)} uyarı")
        for u in uyari[:25]: print("     -", u)
        if len(uyari) > 25: print(f"     … ve {len(uyari)-25} tane daha")
    return len(hata)


def main():
    if len(sys.argv) < 2:
        print(__doc__); return 2
    havuz = json.load(open(sys.argv[1], encoding='utf-8'))

    if len(sys.argv) >= 3:
        yeni = json.load(open(sys.argv[2], encoding='utf-8'))
        h1 = denetle(yeni, TAM, "YENİ PARTİ — tam standart",
                     havuz_disi_promptlar={q['prompt'].strip() for q in havuz},
                     havuz_disi_idler={q['id'] for q in havuz})
        h2 = denetle(havuz + yeni, TABAN, "BİRLEŞİK HAVUZ — taban")
        toplam = h1 + h2
    else:
        toplam = denetle(havuz, TABAN, "HAVUZ — taban")

    print()
    if toplam:
        print(f"SONUÇ: {toplam} hata. Bu sorular havuza EKLENMEZ.")
        return 1
    print("SONUÇ: kapı açık. Sorular havuza eklenebilir.")
    return 0


if __name__ == '__main__':
    sys.exit(main())
