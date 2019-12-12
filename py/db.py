def db_path(local=False):
    if local == True:
        return "/Users/lin/sites/money/db/development.sqlite3"
    else:
        return "/home/jie/sites/money/db/development.sqlite3"
