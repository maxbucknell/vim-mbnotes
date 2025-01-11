import vim
from string import Template
from datetime import datetime, timedelta
daily_template = Template("""---
title: "Daily Note"
date: "$date"
---

# $date

## Daily Note


""")

def generate_daily_note(date_offset = 0):
    """Generate a new daily note.

    By default, this generates a daily note starter for today. The
    `date_offset` argument changes this by offsetting the current date by the
    given number of seconds.

    This function returns a string. To put into a python-buffer, this output
    needs to be split by line into a list and assigned to `buffer[:]`.
    """
    date = datetime.today() + timedelta(seconds=date_offset)
    date_format = vim.eval("g:mbnotes_date_format_long")
    date = date.strftime(date_format)

    return daily_template.substitute(date=date)
