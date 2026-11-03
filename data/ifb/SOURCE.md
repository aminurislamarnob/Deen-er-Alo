# Islamic Foundation Bangladesh (IFB) Permanent Prayer Timetable Source

## 1. Primary Source Document
- **Document Title**: "সাহরী ও ইফতারসহ (ঢাকা) নামাজের স্থায়ী সময়সূচি"
- **Publisher**: ইসলামিক ফাউন্ডেশন বাংলাদেশ (Islamic Foundation Bangladesh - IFB)
- **Official Status**: Official permanent timetable issued for Bangladesh.
- **Verification**: Verified cell-by-cell (504/504 Dhaka cells and all 62 district offsets) against the official published Islamic Foundation document text layer.

## 2. Footnote Rules & Methodology (Official IFB Specification)
The official publication contains four specific rules governing prayer times, fasting boundaries, and prohibited windows:

- **Footnote ক (অন্যান্য জেলার হিসাব)**:
  ঢাকার সময়ের সাথে যোগ/বিয়োগের মাধ্যমে অন্যান্য জেলার সেহরি, সূর্যোদয়, মধ্যাহ্ন, আছর ও মাগরিবের সময় নির্ধারণ করা হয়। কিছু ক্ষেত্রে যোগ/বিয়োগের পরিমাণ কম-বেশি হতে পারে (বিশেষ করে উত্তরবঙ্গে আছরের ক্ষেত্রে)। ঢাকা বাদে অন্যান্য জেলার সূর্যোদয়, যোহর, আছর ও এশার জন্য জ্যোতির্বিজ্ঞানভিত্তিক হিসাব (করাচি হানাফি + সতর্কতা) ব্যবহৃত হয়।
- **Footnote খ (দ্বিপ্রহর / যাওয়াল)**:
  সূর্য ঠিক মধ্য আকাশে থাকার (নিস্ফুন নাহার/যাওয়াল) স্থায়িত্ব ৩ মিনিটের বেশি নয়। তবে সতর্কতামূলক ব্যবস্থা হিসেবে যোহরের জন্য লিখিত সময়ের **৬ মিনিট আগে** থেকে নামাজ পড়া নিষিদ্ধ (Duration = ৬ মিনিট, `dhuhr - 6 min` to `dhuhr`)।
- **Footnote গ (৩ মিনিটের সতর্কতা)**:
  এই সময়সূচীতে ফজর, যোহর ও মাগরিবের নামাজের প্রকৃত সময়ের সাথে সতর্কতামূলক ব্যবস্থা হিসেবে **৩ (তিন) মিনিট যোগ** করা হয়েছে। এই কারণে সাহরির শেষ সময় প্রকৃত সময়ের কমপক্ষে তিন মিনিট পূর্বে (সুবহে সাদিক - ৩ মিনিট) এবং ফজর নামাজের সময় সুবহে সাদিকের তিন মিনিট পর নির্ধারণ করা হয়েছে। ফলে প্রতিটি সারিতে সর্বদা **ফজর = সাহরি + ৬ মিনিট**।
- **Footnote ঘ (নামাজের ৩টি নিষিদ্ধ সময়)**:
  ইসলামী শরীয়তে ৩টি সময়ে নামাজ পড়া নিষিদ্ধ:
  1. **সূর্যোদয়ের সময়**: সূর্য ওঠার সময় থেকে পরবর্তী **২৪ মিনিট** পর্যন্ত।
  2. **দ্বিপ্রহরের সময়**: যোহরের ওয়াক্ত হওয়ার পূর্বের **৬ মিনিট** ব্যাপী।
  3. **সূর্যাস্তের সময়**: সূর্যাস্তের পূর্ববর্তী **২৪ মিনিট** (সেদিনের আসর কাজা না থাকলে)।

## 3. Official Printing Corrections
The source PDF has 3 known printing errors documented and corrected in `data/ifb/corrections.csv`:
1. **June 24 Maghrib/Iftar**: Printed as `5:53` (59-minute typographical error, neighbors are `6:51` and `6:53`). Corrected to **`6:53`**.
2. **June 30 Sehri**: Printed as `3:43` (breaks the `Fajr = Sehri + 6` rule with Fajr at `3:48`). July 1 is `3:42` / `3:48`. Corrected to **`3:42`** (earlier is safer for fasting).
3. **November 24 Fajr**: Printed as `5:00` with Sehri at `4:56` (breaks the `Fajr = Sehri + 6` rule). Corrected to **`5:02`**.

## 4. Derived District (Joypurhat)
- District ID `8509` (Joypurhat) is not individually listed in the 62-district offset table.
- Its offset is mathematically derived as `+7` min Sehri and `+7` min Iftar (consistent with neighboring Bogura `+7/+7` and Naogaon `+8/+8`). It is tagged with `derived: true`.

## 5. Attribution
"নামাজের সময়সূচি ইসলামিক ফাউন্ডেশন বাংলাদেশ কর্তৃক প্রকাশিত স্থায়ী ক্যালেন্ডার অনুযায়ী প্রণীত।"
(Prayer times sourced from the official Islamic Foundation Bangladesh permanent calendar).
