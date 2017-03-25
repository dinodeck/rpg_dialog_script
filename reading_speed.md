 1
down vote


I realize this is a fairly old question, but I got here from google so others probably will too.

I had a similar situation, I needed to show a notification to a user (on a desktop) that could contain any number of words, and of course show this notification for an appropriate amount of time.

I did a little research and drew from the answers from another question, and this is what I came up with (in python):

def getWaitTime(self, text):
    ''' Calculate the amount of time needed to read the notification '''
    wpm = 180  # readable words per minute
    word_length = 5  # standardized number of chars in calculable word
    words = len(text)/word_length
    words_time = ((words/wpm)*60)*1000

    delay = 1500  # milliseconds before user starts reading the notification
    bonus = 1000  # extra time

    return delay + words_time + bonus

180 words-per-minute is suggested on the the Wikipedia article for reading on a computer (as opposed to on paper), though perhaps it is a little slow, my notifications will have obscure file names that might take a little longer to read. This is also why I included the bonus time.

The delay time is to account for the user noticing the notification in the bottom right corner and starting to read it.

The same Wikipedia article mentions that words-per-minute is not technically true, since a "word" is counted every 5 characters (including spaces and punctuation):

    For example, the phrase "I run" counts as one word, but "rhinoceros" and "let's talk" both count as two.

