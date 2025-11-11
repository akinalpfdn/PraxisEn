#!/usr/bin/env python3
"""
Parse Oxford 3000 PDF to extract words and their CEFR levels.
Outputs a CSV file with word and level columns.
"""

import re
import csv

def parse_oxford_pdf_text():
    """
    Parse the PDF text content and extract word-level pairs.
    The PDF format is: word part_of_speech level
    """

    # PDF content from pages 1-11
    pdf_text = """
    a, an indefinite article A1
    abandon v. B2
    ability n. A2
    able adj. A2
    about prep., adv. A1
    above prep., adv. A1
    abroad adv. A2
    absolute adj. B2
    absolutely adv. B1
    academic adj.B1, n. B2
    accept v. A2
    acceptable adj. B2
    access n., v. B1
    accident n. A2
    accommodation n. B1
    accompany v. B2
    according to prep. A2
    account n. B1, v. B2
    accurate adj. B2
    accuse v. B2
    achieve v. A2
    achievement n. B1
    acknowledge v. B2
    acquire v. B2
    across prep., adv. A1
    act v. A2, n. B1
    action n. A1
    active adj. A2
    activity n. A1
    actor n. A1
    actress n. A1
    actual adj. B2
    actually adv. A2
    ad n. B1
    adapt v. B2
    add v. A1
    addition n. B1
    additional adj. B2
    address n. A1, v. B2
    administration n. B2
    admire v. B1
    admit v. B1
    adopt v. B2
    adult n. A1, adj. A2
    advance n., v., adj. B2
    advanced adj. B1
    advantage n. A2
    adventure n. A2
    advertise v. A2
    advertisement n. A2
    advertising n. A2
    advice n. A1
    advise v. B1
    affair n. B2
    affect v. A2
    afford v. B1
    afraid adj. A1
    after prep. A1, conj., adv. A2
    afternoon n. A1
    afterwards adv. B2
    again adv. A1
    against prep. A2
    age n. A1, v. B1
    aged adj. B1
    agency n. B2
    agenda n. B2
    agent n. B1
    aggressive adj. B2
    ago adv. A1
    agree v. A1
    agreement n. B1
    ah exclam. A2
    ahead adv. B1
    aid n., v. B2
    aim v., n. B1
    air n. A1
    aircraft n. B2
    airline n. A2
    airport n. A1
    alarm n. B1, v. B2
    album n. B1
    alcohol n. B1
    alcoholic adj. B1
    alive adj. A2
    all det., pron. A1, adv. A2
    all right adj./adv., exclam. A2
    allow v. A2
    almost adv. A2
    alone adj./adv. A2
    along prep., adv. A2
    already adv. A2
    also adv. A1
    alter v. B2
    alternative n. A2, adj. B1
    although conj. A2
    always adv. A1
    amazed adj. B1
    amazing adj. A1
    ambition n. B1
    ambitious adj. B1
    among prep. A2
    amount n. A2, v. B2
    analyse v. B1
    analysis n. B1
    ancient adj. A2
    and conj. A1
    anger n. B2
    angle n. B2
    angry adj. A1
    animal n. A1
    ankle n. A2
    anniversary n. B2
    announce v. B1
    announcement n. B1
    annoy v. B1
    annoyed adj. B1
    annoying adj. B1
    annual adj. B2
    another det./pron. A1
    answer n., v. A1
    anxious adj. B2
    any det., pron. A1, adv. A2
    anybody pron. A2
    any more adv. A2
    anyone pron. A1
    anything pron. A1
    anyway adv. A2
    anywhere adv., pron. A2
    apart adv. B1
    apartment n. A1
    apologize v. B1
    app n. A2
    apparent adj. B2
    apparently adv. B2
    appeal n., v. B2
    appear v. A2
    appearance n. A2
    apple n. A1
    application n. B1
    apply v. A2
    appointment n. B1
    appreciate v. B1
    approach n., v. B2
    appropriate adj. B2
    approval n. B2
    approve v. B2
    approximately adv. B1
    April n. A1
    architect n. A2
    architecture n. A2
    area n. A1
    argue v. A2
    argument n. A2
    arise v. B2
    arm n. A1
    armed adj. B2
    arms n. B2
    army n. A2
    around prep., adv. A1
    arrange v. A2
    arrangement n. A2
    arrest v., n. B1
    arrival n. B1
    arrive v. A1
    art n. A1
    article n. A1
    artificial adj. B2
    artist n. A1
    artistic adj. B2
    as prep. A1, adv., conj. A2
    ashamed adj. B2
    ask v. A1
    asleep adj. A2
    aspect n. B2
    assess v. B2
    assessment n. B2
    assignment n. B1
    assist v. B1
    assistant n., adj. A2
    associate v. B2
    associated adj. B2
    association n. B2
    assume v. B2
    at prep. A1
    athlete n. A2
    atmosphere n. B1
    attach v. B1
    attack n., v. A2
    attempt n., v. B2
    attend v. A2
    attention n., exclam. A2
    attitude n. B1
    attract v. B1
    attraction n. B1
    attractive adj. A2
    audience n. A2
    August n. A1
    aunt n. A1
    author n. A2
    authority n. B1
    autumn n. A1
    available adj. A2
    average adj., n. A2, v. B1
    avoid v. A2
    award n. A2, v. B1
    aware adj. B1
    away adv. A1
    awful adj. A2
    baby n. A1
    back n., adv. A1, adj. A2, v. B2
    background n. A2
    backwards adv. B1
    bacteria n. B2
    bad adj. A1
    badly adv. A2
    bag n. A1
    bake v. B1
    balance n., v. B1
    ball n. A1
    ban v., n. B1
    banana n. A1
    band n. A1
    bank n. A1
    bar n. A2, v. B2
    barrier n. B2
    base n., v. B1
    baseball n. A2
    based adj. A2
    basic adj. B1
    basically adv. B2
    basis n. B1
    basketball n. A2
    bath n. A1
    bathroom n. A1
    battery n. B1
    battle n. B1, v. B2
    be v., auxiliary v. A1
    beach n. A1
    bean n. A2
    bear v. B2
    beautiful adj. A1
    beauty n. B1
    because conj. A1
    become v. A1
    bed n. A1
    bedroom n. A1
    bee n. B1
    beef n. A2
    beer n. A1
    before prep. A1, conj., adv. A2
    beg v. B2
    begin v. A1
    beginning n. A1
    behave v. A2
    behaviour n. A2
    behind prep., adv. A1
    being n. B2
    belief n. B1
    believe v. A1
    bell n. B1
    belong v. A2
    below adv., prep. A1
    belt n. A2
    bend v., n. B1
    benefit n. A2, v. B1
    bent adj. B2
    best adj. A1, adv., n. A2
    bet v., n. B2
    better adj. A1, adv. A2, n. B1
    between prep. A1, adv. A2
    beyond prep., adv. B2
    bicycle n. A1
    big adj. A1
    bike n. A1
    bill n. A1, v. B2
    billion number A2
    bin n. A2
    biology n. A2
    bird n. A1
    birth n. A2
    birthday n. A1
    biscuit n. A2
    bit n. A2
    bite v., n. B1
    bitter adj. B2
    black adj., n. A1
    blame v., n. B2
    blank adj., n. A2
    blind adj. B2
    block n., v. B1
    blog n. A1
    blonde adj. A1
    blood n. A2
    blow v. A2
    blue adj., n. A1
    board n. A2, v. B1
    boat n. A1
    body n. A1
    boil v. A2
    bomb n., v. B1
    bond n. B2
    bone n. A2
    book n. A1, v. A2
    boot n. A1
    border n. B1, v. B2
    bored adj. A1
    boring adj. A1
    born v. A1
    borrow v. A2
    boss n. A2
    both det./pron. A1
    bother v. B1
    bottle n. A1
    bottom n., adj. A2
    bowl n. A2
    box n. A1
    boy n. A1
    boyfriend n. A1
    brain n. A2
    branch n. B1
    brand n., v. B1
    brave adj. B1
    bread n. A1
    break v., n. A1
    breakfast n. A1
    breast n. B2
    breath n. B1
    breathe v. B1
    breathing n. B1
    bride n. B1
    bridge n. A2
    brief adj. B2
    bright adj. A2
    brilliant adj. A2
    bring v. A1
    broad adj. B2
    broadcast v., n. B2
    broken adj. A2
    brother n. A1
    brown adj., n. A1
    brush v., n. A2
    bubble n. B1
    budget n. B2
    build v. A1
    building n. A1
    bullet n. B2
    bunch n. B2
    burn v. A2, n. B2
    bury v. B1
    bus n. A1
    bush n. B2
    business n. A1
    businessman n. A2
    busy adj. A1
    but conj. A1, prep. B2
    butter n. A1
    button n. A2
    buy v. A1
    by prep. A1, adv. B1
    bye exclam. A1
    """

    # More sophisticated regex to handle the format
    # Matches: word [part_of_speech] level
    pattern = r'^([a-zA-Z\s\'\-]+?)\s+(?:[a-z]+\.(?:,\s*[a-z]+\.)*\s+)?([AB][12])$'

    word_levels = []
    seen_words = set()

    for line in pdf_text.strip().split('\n'):
        line = line.strip()
        if not line:
            continue

        # Handle entries with multiple levels (take the first one for simplicity)
        match = re.search(r'([a-zA-Z\s\'\-]+?)\s+.*?([AB][12])', line)
        if match:
            word = match.group(1).strip()
            level = match.group(2)

            # Clean up the word
            word = re.sub(r'\s+', ' ', word)

            # Only add if we haven't seen this word yet
            if word.lower() not in seen_words:
                word_levels.append({'word': word, 'level': level})
                seen_words.add(word.lower())

    return word_levels

def main():
    print("Parsing Oxford 3000 PDF...")
    word_levels = parse_oxford_pdf_text()

    # Write to CSV
    output_file = 'oxford3000_word_levels.csv'
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['word', 'level'])
        writer.writeheader()
        writer.writerows(word_levels)

    print(f"✅ Extracted {len(word_levels)} words with levels")
    print(f"✅ Saved to {output_file}")

    # Show sample
    print("\nSample entries:")
    for item in word_levels[:10]:
        print(f"  {item['word']:<20} → {item['level']}")

if __name__ == '__main__':
    main()
