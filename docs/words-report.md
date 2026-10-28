# Georgian word database — quality report

Re-run with `python3 tools/words/words_report.py`. Everything below the marker is
generated; this top section is hand-written and survives a re-run.

## Where the words come from

**The data.** The Georgian list is one SQLite file bundled in the app:
`Libraries/Packages/GamoitsaniData/Sources/GamoitsaniData/WordFiles/words_ka.db`.
It holds **6,374 words** (`meta.content_version` 20260909), not the ~20,000 sometimes
quoted. That figure does not match anything in this repo or its history. The schema is
frozen and documented in `docs/2.0/WORD-DB-SCHEMA.md`:

- `words`: `id` (stable forever), `lemma` (the card text), `pos`, `difficulty` 1–5,
  `concreteness` 1–5, `familiarity` 1–5, `is_describable`, `is_actable`,
  `is_family_safe`
- `categories`: a two-level tree of 15 branches and 166 leaves, each with a slug, a
  Georgian name and an English name
- `word_categories`: many-to-many, so one word can sit in several leaves
- `taboo_terms`: present but empty
- `meta`: `schema_version`, `content_version`, `language`, `word_count`

The ten other `words_<lang>.db` files beside it share the schema. They were exported
once from v1's Firestore, have no categories and are outside this report.

**The pipeline.** The Georgian file is *not* built by code in this repo. It comes
from the separate word project. There, words go through a review pipeline in a
working database, and `scripts/export_app_db.py` (in that project) exports only
`status='approved'` rows into `words_ka.db`. That file is then copied in by hand. See
`docs/2.0/WORD-DB.md`. The only word pipeline in *this* repo is
`scripts/export_firestore_words.py`, a one-time exporter for the ten non-Georgian
languages. It skips Georgian by default.

Fixes therefore belong upstream: change the word in the working database, re-export,
and re-bundle. Editing `words_ka.db` here would be overwritten by the next export.

## How to read this report

- **The removals CSV holds suggestions, not decisions.** `tools/words/suggested-removals.csv`
  has one row per entry finding (`id`, `lemma`, `check`, `reason`). Nothing was
  deleted or edited.
- **The "too short" rule flags real words.** The 1–2 letter rule was requested and is
  applied as written. Every Georgian two-letter lemma it catches is an ordinary
  noun, though: ხე tree, ცა sky, ბუ owl, კუ turtle, ია violet, ჭა well, და sister.
  They play fine on a card, so the recommendation is to keep them.
- **Hyphenated proper names are not flagged.** Entries like ნიუ-იორკი and
  რიო-დე-ჟანეირო are the correct Georgian spelling, so a hyphen between letters is
  allowed.

<!-- GENERATED BELOW by tools/words/words_report.py — edits under this line are overwritten -->

## Results

Source: `Libraries/Packages/GamoitsaniData/Sources/GamoitsaniData/WordFiles/words_ka.db` · content_version `20260909` · 6,374 words · 181 categories

| Check | Entries |
|---|---:|
| Exact duplicate | 0 |
| Duplicate after normalising | 0 |
| Latin letters | 0 |
| Digits | 0 |
| Other scripts | 0 |
| Stray symbols or spacing | 0 |
| Too short (1-2 letters) | 7 |
| Too long (more than 3 words) | 0 |
| Field problems | 0 |
| **Distinct words in `suggested-removals.csv`** | **7** |

## Entry checks

Duplicates are matched exactly, then again after NFKC, case-folding and dropping every character that is not a letter or digit (spaces, hyphens, punctuation). In each group the lowest id is kept, since players' seen-lists are keyed on it.

Allowed characters are Mkhedruli letters (U+10D0–U+10FA), plus a single space or hyphen between letters. A hyphen joins rather than splits, so `რიო-დე-ჟანეირო` counts as one word.

### Exact duplicate — 0

None.

### Duplicate after normalising — 0

None.

### Latin letters — 0

None.

### Digits — 0

None.

### Other scripts — 0

None.

### Stray symbols or spacing — 0

None.

### Too short (1-2 letters) — 7

| id | lemma | reason |
|---:|---|---|
| 699 | ბუ | too short: 2 letter(s) |
| 1338 | და | too short: 2 letter(s) |
| 2299 | ია | too short: 2 letter(s) |
| 2767 | კუ | too short: 2 letter(s) |
| 6369 | ცა | too short: 2 letter(s) |
| 6647 | ჭა | too short: 2 letter(s) |
| 6775 | ხე | too short: 2 letter(s) |

### Too long (more than 3 words) — 0

None.

## Field checks

Checked against the frozen schema in `docs/2.0/WORD-DB-SCHEMA.md`: `pos` in noun / verb / adj / propn; `difficulty`, `concreteness`, `familiarity` present and 1–5; the three `is_*` flags present and 0 or 1; every word in at least one leaf category that exists; every category under a branch that exists. These are metadata fixes, not removals, so they are not in the CSV.

No missing or inconsistent fields.

Not errors, but these columns carry no information yet:

- `is_describable` is `1` for every word
- `is_family_safe` is `1` for every word

## Counts per difficulty

| difficulty | words | share |
|---|---:|---:|
| 1 | 662 | 10.4% |
| 2 | 2,108 | 33.1% |
| 3 | 2,771 | 43.5% |
| 4 | 818 | 12.8% |
| 5 | 15 | 0.2% |

The setup screen's tiers (`WordDifficulty`):

| tier | words |
|---|---:|
| easy (≤ 2) | 2,770 |
| medium (≤ 3) | 5,541 |
| hard (≥ 4) | 833 |
| mixed (all) | 6,374 |

## Counts per category

9,608 word–category links for 6,374 words: a word can sit in several leaves and even several branches, so the columns below do not add up to the word count. Counts are distinct words.

### Branches

| branch | slug | words |
|---|---|---:|
| ცოცხალი ბუნება (Living world) | `living` | 425 |
| საკვები და სასმელი (Food & drink) | `food` | 426 |
| ადამიანი (Human) | `human` | 669 |
| სახლი და საგნები (Home & objects) | `home` | 374 |
| ტანსაცმელი (Clothing) | `clothing` | 205 |
| ტექნიკა და ტრანსპორტი (Technology & transport) | `tech` | 443 |
| ადგილები (Places) | `places` | 669 |
| ბუნება და გარემო (Nature & environment) | `nature` | 411 |
| აქტივობები და კულტურა (Activities & culture) | `culture` | 766 |
| საზოგადოება (Society) | `society` | 1,087 |
| ყოფა და საქმიანობა (Daily life & occupations) | `daily` | 625 |
| სახელები და ბრენდები (Names & brands) | `names` | 188 |
| აბსტრაქტული ცნებები (Abstract concepts) | `abstract` | 388 |
| მოქმედებები (Actions) | `actions` | 945 |
| თვისებები (Qualities) | `qualities` | 1,105 |

### Leaves

120 of 166 leaves have 40 or more words.

| branch | leaf | slug | words |
|---|---|---|---:|
| `living` | შინაური ცხოველები (Pets) | `animals_pets` | 30 |
| `living` | პირუტყვი (Farm animals) | `animals_farm` | 23 |
| `living` | ველური ცხოველები (Wild animals) | `animals_wild` | 53 |
| `living` | ფრინველები (Birds) | `animals_birds` | 49 |
| `living` | მწერები (Insects) | `animals_insects` | 32 |
| `living` | ზღვის ბინადრები (Sea creatures) | `animals_sea` | 38 |
| `living` | ქვეწარმავლები და ამფიბიები (Reptiles & amphibians) | `animals_reptiles` | 17 |
| `living` | ცხოველის ნაწილები (Animal body parts) | `animal_parts` | 50 |
| `living` | ხეები და ბუჩქები (Trees & shrubs) | `plants_trees` | 27 |
| `living` | ყვავილები (Flowers) | `plants_flowers` | 21 |
| `living` | მცენარეები (Plants) | `plants_wild` | 61 |
| `living` | მცენარის ნაწილები (Plant parts) | `plant_parts` | 31 |
| `food` | ხილი (Fruit) | `food_fruits` | 45 |
| `food` | ბოსტნეული (Vegetables) | `food_vegetables` | 30 |
| `food` | ხორცი და თევზი (Meat & fish) | `food_meat_fish` | 52 |
| `food` | რძის პროდუქტები (Dairy) | `food_dairy` | 15 |
| `food` | პური და ცომეული (Bread & pastry) | `food_bakery` | 29 |
| `food` | ტკბილეული (Sweets) | `food_sweets` | 21 |
| `food` | სანელებლები (Spices & herbs) | `food_spices` | 38 |
| `food` | კერძები (Dishes) | `food_dishes` | 36 |
| `food` | ქართული სამზარეულო (Georgian cuisine) | `food_georgian` | 74 |
| `food` | უალკოჰოლო სასმელები (Soft drinks) | `drinks_soft` | 25 |
| `food` | ალკოჰოლური სასმელები (Alcoholic drinks) | `drinks_alcohol` | 24 |
| `food` | სამზარეულო პროცესები (Cooking) | `cooking` | 48 |
| `human` | სხეულის ნაწილები (Body parts) | `body_external` | 60 |
| `human` | შინაგანი ორგანოები (Internal organs) | `body_internal` | 25 |
| `human` | ორგანიზმის პროცესები (Bodily processes) | `body_processes` | 53 |
| `human` | ნათესაობა (Family & kinship) | `family_relations` | 64 |
| `human` | ტრადიციული პროფესიები (Traditional professions) | `professions_trad` | 94 |
| `human` | თანამედროვე პროფესიები (Modern professions) | `professions_modern` | 150 |
| `human` | ემოციები (Emotions) | `emotions_nouns` | 83 |
| `human` | ასაკი და ცხოვრების ეტაპები (Age & life stages) | `human_lifecycle` | 54 |
| `human` | გარეგნობა (Appearance) | `appearance_nouns` | 58 |
| `human` | ხასიათი (Character) | `personality_nouns` | 70 |
| `home` | ავეჯი (Furniture) | `furniture` | 23 |
| `home` | სამზარეულოს ჭურჭელი (Kitchen utensils) | `kitchen_utensils` | 32 |
| `home` | სუფრის ჭურჭელი (Tableware) | `tableware` | 24 |
| `home` | აბაზანის ნივთები (Bathroom items) | `bathroom_items` | 31 |
| `home` | საძინებლის ნივთები (Bedroom items) | `bedroom_items` | 27 |
| `home` | ხელსაწყოები (Hand tools) | `tools_hand` | 50 |
| `home` | ჭურჭელი და კონტეინერები (Containers) | `containers` | 44 |
| `home` | საოჯახო ქსოვილები (Home textiles) | `textiles_home` | 34 |
| `home` | დასუფთავების საშუალებები (Cleaning supplies) | `cleaning_items` | 18 |
| `home` | განათება და გათბობა (Lighting & heating) | `lighting_heating` | 48 |
| `home` | დეკორი (Decor) | `decor_items` | 45 |
| `home` | საკანცელარიო ნივთები (Stationery) | `stationery` | 46 |
| `clothing` | ზედა ტანსაცმელი (Outerwear) | `clothing_outer` | 31 |
| `clothing` | საცვლები (Underwear) | `clothing_inner` | 15 |
| `clothing` | ფეხსაცმელი (Footwear) | `footwear` | 17 |
| `clothing` | თავსაბურავი (Headwear) | `headwear` | 25 |
| `clothing` | აქსესუარები (Accessories) | `accessories` | 33 |
| `clothing` | სამკაულები (Jewellery) | `jewelry` | 34 |
| `clothing` | ქსოვილები (Fabrics) | `fabrics` | 24 |
| `clothing` | კერვა (Sewing) | `sewing` | 39 |
| `tech` | ელექტრონიკა (Electronics) | `electronics_home` | 63 |
| `tech` | საოჯახო ტექნიკა (Appliances) | `appliances` | 33 |
| `tech` | კომპიუტერი და ინტერნეტი (Computers & internet) | `computers` | 82 |
| `tech` | ტელეფონი და მედია (Phones & media) | `phones_media` | 72 |
| `tech` | სახმელეთო ტრანსპორტი (Road vehicles) | `vehicles_road` | 32 |
| `tech` | რკინიგზა, საჰაერო და საზღვაო (Rail, air & sea) | `vehicles_other` | 65 |
| `tech` | ავტომობილის ნაწილები (Vehicle parts) | `vehicle_parts` | 48 |
| `tech` | დანადგარები (Machines) | `machines` | 47 |
| `tech` | ენერგია (Energy) | `energy` | 60 |
| `places` | შენობები (Buildings) | `buildings` | 72 |
| `places` | ოთახები და სივრცეები (Rooms & spaces) | `rooms` | 54 |
| `places` | ქალაქის ინფრასტრუქტურა (City infrastructure) | `city_infra` | 78 |
| `places` | მაღაზიები და სერვისები (Shops & services) | `shops` | 81 |
| `places` | რელიეფი (Landforms) | `landforms` | 54 |
| `places` | წყალსატევები (Bodies of water) | `water_bodies` | 28 |
| `places` | ქვეყნები (Countries) | `countries` | 88 |
| `places` | მსოფლიო ადგილები (World places) | `world_places` | 91 |
| `places` | ქართული ადგილები (Georgian places) | `georgian_places` | 158 |
| `nature` | ამინდი (Weather) | `weather` | 46 |
| `nature` | სეზონები (Seasons) | `seasons` | 53 |
| `nature` | კოსმოსი (Space & astronomy) | `space` | 50 |
| `nature` | მასალები (Materials) | `materials` | 76 |
| `nature` | მინერალები და ლითონები (Minerals & metals) | `minerals` | 45 |
| `nature` | ლანდშაფტი (Landscape) | `landscape` | 60 |
| `nature` | ბუნებრივი მოვლენები (Natural phenomena) | `phenomena` | 55 |
| `nature` | ეკოლოგია (Ecology) | `ecology` | 57 |
| `culture` | სპორტის სახეობები (Sports) | `sports_types` | 46 |
| `culture` | სპორტული ინვენტარი (Sports equipment) | `sports_equipment` | 45 |
| `culture` | თამაშები და სათამაშოები (Games & toys) | `games_toys` | 49 |
| `culture` | მუსიკალური ინსტრუმენტები (Musical instruments) | `music_instruments` | 37 |
| `culture` | მუსიკა (Music) | `music_terms` | 69 |
| `culture` | ხელოვნება და რეწვა (Arts & crafts) | `arts_crafts` | 97 |
| `culture` | ლიტერატურა (Literature) | `literature` | 86 |
| `culture` | კინო და თეატრი (Cinema & theatre) | `cinema_theatre` | 75 |
| `culture` | ცეკვა (Dance) | `dance` | 35 |
| `culture` | ფოტოგრაფია (Photography) | `photography` | 40 |
| `culture` | დღესასწაულები (Holidays) | `holidays` | 55 |
| `culture` | ქართული ტრადიციები (Georgian traditions) | `georgian_traditions` | 51 |
| `culture` | რელიგია (Religion) | `religion` | 96 |
| `culture` | მითოლოგია (Mythology) | `mythology` | 57 |
| `society` | განათლება (Education) | `education` | 102 |
| `society` | მედიცინა (Medicine) | `medicine` | 87 |
| `society` | დაავადებები (Diseases) | `diseases` | 78 |
| `society` | სამართალი (Law) | `law` | 72 |
| `society` | სახელმწიფო და პოლიტიკა (Government & politics) | `government` | 69 |
| `society` | ფული და ფინანსები (Money & finance) | `money` | 93 |
| `society` | ბიზნესი და სამუშაო (Business & work) | `business` | 90 |
| `society` | სამხედრო (Military) | `military` | 100 |
| `society` | მოგზაურობა (Travel) | `travel` | 84 |
| `society` | მეცნიერება (Science) | `science` | 88 |
| `society` | მათემატიკა და ფიგურები (Maths & shapes) | `math` | 75 |
| `society` | ენა და წერა (Language & writing) | `language` | 59 |
| `society` | დრო და კალენდარი (Time & calendar) | `time_calendar` | 57 |
| `society` | მედია და ახალი ამბები (Media & news) | `media` | 52 |
| `society` | საზოგადოებრივი ცხოვრება (Social life) | `social_life` | 62 |
| `daily` | სოფლის მეურნეობა (Agriculture) | `agriculture` | 87 |
| `daily` | მშენებლობა (Construction) | `construction` | 88 |
| `daily` | თევზაობა და ნადირობა (Fishing & hunting) | `fishing_hunting` | 63 |
| `daily` | სასწავლო საგნები (School subjects) | `school_subjects` | 41 |
| `daily` | დანაშაული და უსაფრთხოება (Crime & safety) | `crime_safety` | 73 |
| `daily` | საგანგებო სამსახურები (Emergency services) | `emergency` | 46 |
| `daily` | სილამაზე და კოსმეტიკა (Beauty & cosmetics) | `beauty` | 60 |
| `daily` | ბავშვის მოვლა (Childcare) | `childcare` | 58 |
| `daily` | ცხოველის მოვლა (Pet care) | `pet_care` | 44 |
| `daily` | ბაღი და მებაღეობა (Garden & gardening) | `garden` | 68 |
| `daily` | სტიქიური უბედურებები (Natural disasters) | `disasters` | 40 |
| `daily` | შეფუთვა (Packaging) | `packaging` | 37 |
| `names` | საერთაშორისო ბრენდები (International brands) | `brands_intl` | 104 |
| `names` | ქართველი პიროვნებები (Georgian figures) | `georgian_people` | 22 |
| `names` | მსოფლიო პიროვნებები (World figures) | `world_figures` | 62 |
| `abstract` | განწყობა და მდგომარეობა (Moods & states) | `feelings_states` | 84 |
| `abstract` | ცნებები (Ideas & concepts) | `ideas_concepts` | 105 |
| `abstract` | ურთიერთობები (Relationships) | `relationships` | 81 |
| `abstract` | დროის ცნებები (Time concepts) | `time_concepts` | 60 |
| `abstract` | თვისებები (Qualities) | `qualities_nouns` | 81 |
| `actions` | მოძრაობა (Movement) | `v_movement` | 87 |
| `actions` | მეტყველება (Speech) | `v_speech` | 91 |
| `actions` | აღქმა (Perception) | `v_perception` | 37 |
| `actions` | ჭამა და სმა (Eating & drinking) | `v_eating` | 33 |
| `actions` | შრომა (Work) | `v_work` | 95 |
| `actions` | საოჯახო საქმე (Household chores) | `v_household` | 66 |
| `actions` | ხელით მოქმედება (Hand actions) | `v_hand` | 99 |
| `actions` | სხეულის მოქმედება (Body actions) | `v_body` | 50 |
| `actions` | ემოციური მოქმედება (Emotional actions) | `v_emotion` | 62 |
| `actions` | აზროვნება (Thinking) | `v_thinking` | 53 |
| `actions` | სოციალური ურთიერთობა (Social actions) | `v_social` | 68 |
| `actions` | შექმნა და ნგრევა (Creating & destroying) | `v_creation` | 69 |
| `actions` | ცვლილება (Change of state) | `v_change` | 113 |
| `actions` | სპორტული მოქმედება (Sports actions) | `v_sports` | 34 |
| `actions` | შემოქმედება (Artistic actions) | `v_art` | 40 |
| `actions` | ბუნებრივი მოვლენები (Nature actions) | `v_nature` | 49 |
| `actions` | ყიდვა-გაყიდვა (Buying & selling) | `v_transaction` | 51 |
| `actions` | მოვლა და დახმარება (Care & helping) | `v_care` | 55 |
| `qualities` | ფერები (Colours) | `adj_colors` | 33 |
| `qualities` | ზომა და ფორმა (Size & shape) | `adj_size` | 66 |
| `qualities` | ფაქტურა (Texture) | `adj_texture` | 49 |
| `qualities` | გემო და სუნი (Taste & smell) | `adj_taste` | 45 |
| `qualities` | ტემპერატურა (Temperature) | `adj_temperature` | 21 |
| `qualities` | ემოციური მდგომარეობა (Emotional states) | `adj_emotion` | 51 |
| `qualities` | ხასიათი (Character traits) | `adj_character` | 163 |
| `qualities` | გარეგნობა (Appearance) | `adj_appearance` | 74 |
| `qualities` | ასაკი და დრო (Age & time) | `adj_age` | 73 |
| `qualities` | სისწრაფე (Speed) | `adj_speed` | 30 |
| `qualities` | ხარისხი (Quality & value) | `adj_quality` | 93 |
| `qualities` | რაოდენობა (Quantity) | `adj_quantity` | 57 |
| `qualities` | ფიზიკური მდგომარეობა (Physical state) | `adj_physical` | 87 |
| `qualities` | ხმა (Sound) | `adj_sound` | 25 |
| `qualities` | სირთულე (Difficulty) | `adj_difficulty` | 50 |
| `qualities` | სოციალური (Social) | `adj_social` | 105 |
| `qualities` | სივრცე (Spatial) | `adj_spatial` | 89 |
| `qualities` | მორალი (Moral) | `adj_moral` | 60 |
| `qualities` | ხშირი ზედსართავები (Common adjectives) | `adj_common` | 107 |
