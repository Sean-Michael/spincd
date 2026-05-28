"""Curated scanned CD collection for the registry.

Each entry maps an album to its metadata, cover-derived theme colors
(hue/accent extracted from the processed front scan), and the per-face scan
paths under scans/processed. Scan URLs are built at seed time (see seed.py).
"""


def _faces(slug: str) -> dict[str, str]:
    """Standard front/back/disc paths for a single processed-scan slug."""
    return {
        "front": f"{slug}/front.jpg",
        "back": f"{slug}/back.jpg",
        "disc": f"{slug}/disc.jpg",
    }


SEED: list[dict] = [
    {
        "artist": "Daft Punk", "title": "Discovery", "release_year": 2001,
        "genre": ["French House", "Disco", "Nu-Disco"], "label": "Virgin Records",
        "hue": 90, "accent": "#2E2F2D", "added": "2024-01-08", "rating": 5, "notes": None,
        "scans": _faces("Daft Punk_Discovery"),
        "tracks": ["One More Time", "Aerodynamic", "Digital Love", "Harder, Better, Faster, Stronger", "Crescendolls", "Nightvision", "Superheroes", "High Life", "Something About Us", "Voyager", "Veridis Quo", "Short Circuit", "Face to Face", "Too Long"],
    },
    {
        "artist": "Nirvana", "title": "In Utero", "release_year": 1993,
        "genre": ["Grunge", "Alternative Rock", "Noise Rock"], "label": "DGC Records",
        "hue": 53, "accent": "#E1DCB4", "added": "2024-01-22", "rating": 5, "notes": None,
        "scans": _faces("Nirvana_In Utero"),
        "tracks": ["Serve the Servants", "Scentless Apprentice", "Heart-Shaped Box", "Rape Me", "Frances Farmer Will Have Her Revenge on Seattle", "Dumb", "Very Ape", "Milk It", "Pennyroyal Tea", "Radio Friendly Unit Shifter", "Tourette's", "All Apologies"],
    },
    {
        "artist": "The Black Crowes", "title": "The Southern Harmony and Musical Companion", "release_year": 1992,
        "genre": ["Blues Rock", "Hard Rock", "Southern Rock"], "label": "Def American",
        "hue": 23, "accent": "#6C4932", "added": "2024-02-05", "rating": 4, "notes": None,
        "scans": _faces("The Black Crowes_The Southern Harmony and Musical Companion"),
        "tracks": ["Sting Me", "Remedy", "Thorn in My Pride", "Bad Luck Blue Eyes Goodbye", "Sometimes Salvation", "Hotel Illness", "Black Moon Creeping", "No Speak No Slave", "My Morning Song", "Time Will Tell"],
    },
    {
        "artist": "Daft Punk", "title": "Homework", "release_year": 1997,
        "genre": ["French House", "Techno", "Disco"], "label": "Virgin Records",
        "hue": 11, "accent": "#C56C57", "added": "2024-02-19", "rating": 5, "notes": None,
        "scans": _faces("daft punk-homework"),
        "tracks": ["Daftendirekt", "WDPK 83.7 FM", "Revolution 909", "Da Funk", "Phoenix", "Fresh", "Around the World", "Rollin' & Scratchin'", "Teachers", "High Fidelity", "Rock'n Roll", "Oh Yeah", "Burnin'", "Indo Silver Club", "Alive", "Funk Ad"],
    },
    {
        "artist": "Daft Punk", "title": "Random Access Memories", "release_year": 2013,
        "genre": ["Disco", "Funk", "Electronic"], "label": "Columbia Records",
        "hue": 149, "accent": "#292B2A", "added": "2024-03-04", "rating": 5, "notes": None,
        "scans": _faces("daft punk_random access memories"),
        "tracks": ["Give Life Back to Music", "The Game of Love", "Giorgio by Moroder", "Within", "Instant Crush", "Lose Yourself to Dance", "Touch", "Get Lucky", "Beyond", "Motherboard", "Fragments of Time", "Doin' It Right", "Contact"],
    },
    {
        "artist": "Dire Straits", "title": "Brothers in Arms", "release_year": 1985,
        "genre": ["Pop Rock", "Roots Rock"], "label": "Vertigo Records",
        "hue": 217, "accent": "#8797B2", "added": "2024-03-18", "rating": 4, "notes": None,
        "scans": _faces("dire straits_brothers in arms"),
        "tracks": ["So Far Away", "Money for Nothing", "Walk of Life", "Your Latest Trick", "Why Worry", "Ride Across the River", "The Man's Too Strong", "One World", "Brothers in Arms"],
    },
    {
        "artist": "Dire Straits", "title": "Dire Straits", "release_year": 1978,
        "genre": ["Blues Rock", "Pub Rock"], "label": "Vertigo Records",
        "hue": 57, "accent": "#E6E5CB", "added": "2024-04-01", "rating": 4, "notes": None,
        "scans": {
            "front": "dire straits_dire straits/front.jpg",
            "back": "dire straits_direstraits/back.jpg",
            "disc": "dire straits_direstraits/disc.jpg",
        },
        "tracks": ["Down to the Waterline", "Water of Love", "Setting Me Up", "Six Blade Knife", "Southbound Again", "Sultans of Swing", "In the Gallery", "Wild West End", "Lions"],
    },
    {
        "artist": "Fiona Apple", "title": "When the Pawn...", "release_year": 1999,
        "genre": ["Alternative Pop", "Baroque Pop", "Jazz Pop"], "label": "Epic Records",
        "hue": 6, "accent": "#B04234", "added": "2024-04-15", "rating": 5, "notes": None,
        "scans": _faces("fiona apple_when the pawn"),
        "tracks": ["On the Bound", "To Your Love", "Limp", "Love Ridden", "Paper Bag", "A Mistake", "Fast as You Can", "The Way Things Are", "Get Gone", "I Know"],
    },
    {
        "artist": "Grimes", "title": "Art Angels", "release_year": 2015,
        "genre": ["Art Pop", "Synth-Pop", "Dance-Pop"], "label": "4AD",
        "hue": 204, "accent": "#1F6495", "added": "2024-04-29", "rating": 5, "notes": None,
        "scans": _faces("grimes_art angels"),
        "tracks": ["Laughing and Not Being Normal", "California", "Scream", "Flesh Without Blood", "Belly of the Beat", "Kill V. Maim", "Artangels", "Easily", "Pin", "Realiti", "World Princess Part II", "Venus Fly", "Life in the Vivid Dream", "Butterfly"],
    },
    {
        "artist": "Grimes", "title": "Genesis", "release_year": 2012,
        "genre": ["Synth-Pop", "Electropop"], "label": "4AD",
        "hue": 60, "accent": "#20201E", "added": "2024-05-13", "rating": 4,
        "notes": "Single (from Visions); cassette includes B-side Ambrosia.",
        "scans": {
            "front": None,
            "back": "grimes_genesis/back.jpg",
            "disc": "grimes_genesis/disc.jpg",
        },
        "tracks": ["Genesis", "Ambrosia"],
    },
    {
        "artist": "Grimes", "title": "Miss Anthropocene", "release_year": 2020,
        "genre": ["Art Pop", "Electropop", "Industrial"], "label": "4AD",
        "hue": 60, "accent": "#30302F", "added": "2024-05-27", "rating": 4, "notes": None,
        "scans": {
            "front": "grimes_miss anthropecene/front.jpg",
            "back": "grimes_miss anthropocene/back.jpg",
            "disc": "grimes_miss anthropocene/disc.jpg",
        },
        "tracks": ["So Heavy I Fell Through the Earth", "Darkseid", "Delete Forever", "Violence", "4ÆM", "New Gods", "My Name Is Dark", "You'll Miss Me When I'm Not Around", "Before the Fever", "Idoru"],
    },
    {
        "artist": "Lucinda Williams", "title": "Lucinda Williams", "release_year": 1988,
        "genre": ["Alternative Country", "Americana", "Roots Rock"], "label": "Rough Trade Records",
        "hue": 240, "accent": "#2F2F30", "added": "2024-06-10", "rating": 5, "notes": None,
        "scans": _faces("lucinda williams_lucinda williams"),
        "tracks": ["I Just Wanted to See You So Bad", "The Night's Too Long", "Abandoned", "Big Red Sun Blues", "Like a Rose", "Changed the Locks", "Passionate Kisses", "Am I Too Blue", "Crescent City", "Side of the Road", "Price to Pay", "I Asked for Water (He Gave Me Gasoline)"],
    },
    {
        "artist": "Nirvana", "title": "Bleach", "release_year": 1989,
        "genre": ["Grunge", "Punk Rock", "Alternative Rock"], "label": "Sub Pop",
        "hue": 74, "accent": "#2D2E2A", "added": "2024-06-24", "rating": 4, "notes": None,
        "scans": _faces("nirvana_bleach"),
        "tracks": ["Blew", "Floyd the Barber", "About a Girl", "School", "Love Buzz", "Paper Cuts", "Negative Creep", "Scoff", "Swap Meet", "Mr. Moustache", "Sifting"],
    },
    {
        "artist": "Placebo", "title": "Meds", "release_year": 2006,
        "genre": ["Alternative Rock"], "label": "Virgin Records",
        "hue": 36, "accent": "#5B5751", "added": "2024-07-08", "rating": 4, "notes": None,
        "scans": _faces("placebo_meds"),
        "tracks": ["Meds", "Infra-Red", "Drag", "Space Monkey", "Follow the Cops Back Home", "Post Blue", "Because I Want You", "Blind", "Pierrot the Clown", "Broken Promise", "One of a Kind", "In the Cold Light of Morning", "Song to Say Goodbye"],
    },
    {
        "artist": "Rage Against the Machine", "title": "Live at the Grand Olympic Auditorium", "release_year": 2003,
        "genre": ["Rap Metal", "Alternative Metal", "Funk Metal"], "label": "Epic Records",
        "hue": 0, "accent": "#CD3332", "added": "2024-07-22", "rating": 4, "notes": None,
        "scans": _faces("rage against the machine_live at the grand olmpic auditorium"),
        "tracks": ["Bulls on Parade", "Bullet in the Head", "Born of a Broken Man", "Killing in the Name", "Calm Like a Bomb", "Testify", "Bombtrack", "War Within a Breath", "I'm Housin'", "Sleep Now in the Fire", "People of the Sun", "Guerrilla Radio", "Kick Out the Jams", "Know Your Enemy", "No Shelter", "Freedom"],
    },
    {
        "artist": "Talking Heads", "title": "Speaking in Tongues", "release_year": 1983,
        "genre": ["New Wave", "Funk Rock", "Art Rock"], "label": "Sire Records",
        "hue": 44, "accent": "#E4AC08", "added": "2024-08-05", "rating": 5, "notes": None,
        "scans": _faces("talking heads_speaking in tongues"),
        "tracks": ["Burning Down the House", "Making Flippy Floppy", "Girlfriend Is Better", "Slippery People", "I Get Wild/Wild Gravity", "Swamp", "Moon Rocks", "Pull Up the Roots", "This Must Be the Place (Naive Melody)"],
    },
    {
        "artist": "The Black Keys", "title": "El Camino", "release_year": 2011,
        "genre": ["Garage Rock", "Blues Rock", "Indie Rock"], "label": "Nonesuch Records",
        "hue": 39, "accent": "#92866F", "added": "2024-08-19", "rating": 4, "notes": None,
        "scans": _faces("the black keys_el camino"),
        "tracks": ["Lonely Boy", "Dead and Gone", "Gold on the Ceiling", "Little Black Submarines", "Money Maker", "Run Right Back", "Sister", "Hell of a Season", "Stop Stop", "Nova Baby", "Mind Eraser"],
    },
    {
        "artist": "The Growlers", "title": "Chinese Fountain", "release_year": 2014,
        "genre": ["Garage Rock", "Psychedelic Rock", "Surf Rock"], "label": "Everloving Records",
        "hue": 2, "accent": "#CC322C", "added": "2024-09-02", "rating": 4, "notes": None,
        "scans": _faces("the growlers_chinese fountain"),
        "tracks": ["Big Toe", "Black Memories", "Chinese Fountain", "Dull Boy", "Good Advice", "Going Gets Tough", "Magnificent Sadness", "Love Test", "Not the Man", "Rare Hearts", "Purgatory Drive"],
    },
    {
        "artist": "The Raconteurs", "title": "Broken Boy Soldiers", "release_year": 2006,
        "genre": ["Alternative Rock", "Garage Rock", "Power Pop"], "label": "Third Man Records",
        "hue": 26, "accent": "#8E694B", "added": "2024-09-16", "rating": 4, "notes": None,
        "scans": _faces("the raconteurs_broken boy soldiers"),
        "tracks": ["Steady, As She Goes", "Hands", "Broken Boy Soldier", "Intimate Secretary", "Together", "Level", "Store Bought Bones", "Yellow Sun", "Call It a Day", "Blue Veins"],
    },
    {
        "artist": "The Strokes", "title": "The New Abnormal", "release_year": 2020,
        "genre": ["Indie Rock", "New Wave", "Post-Punk Revival"], "label": "RCA Records",
        "hue": 41, "accent": "#C5962F", "added": "2024-09-30", "rating": 4, "notes": None,
        "scans": _faces("the strokes_the new abnormal"),
        "tracks": ["The Adults Are Talking", "Selfless", "Brooklyn Bridge to Chorus", "Bad Decisions", "Eternal Summer", "At the Door", "Why Are Sundays So Depressing", "Not the Same Anymore", "Ode to the Mets"],
    },
    {
        "artist": "Tom Petty and the Heartbreakers", "title": "Greatest Hits", "release_year": 1993,
        "genre": ["Rock", "Heartland Rock"], "label": "MCA Records",
        "hue": 356, "accent": "#93464A", "added": "2024-10-14", "rating": 5, "notes": None,
        "scans": _faces("tom petty and the heartbreakers_greatest hits"),
        "tracks": ["American Girl", "Breakdown", "Listen to Her Heart", "I Need to Know", "Refugee", "Don't Do Me Like That", "Even the Losers", "Here Comes My Girl", "The Waiting", "You Got Lucky", "Don't Come Around Here No More", "I Won't Back Down", "Runnin' Down a Dream", "Free Fallin'", "Learning to Fly", "Into the Great Wide Open", "Mary Jane's Last Dance", "Something in the Air"],
    },
]
