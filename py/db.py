def db_path(local=False):
    if local == True:
        return "/Users/lin/sites/money/db/development.sqlite3"
    else:
        return "/home/jie/sites/money/db/development.sqlite3"

def test_db_path(local=False):
    if local == True:
        return "/Users/lin/sites/money/db/development_test.sqlite3"
    else:
        return "/home/jie/sites/money/db/development_test.sqlite3"

def get_params_path(local=False):
    if local == True:
        return "/Users/lin/sites/money/py/auto_invest_params_local.txt"
    else:
        return "/home/jie/sites/money/py/auto_invest_params.txt"

def get_other_params_path(local=False):
    if local == True:
        return "/Users/lin/sites/money2/py/auto_invest_params_local.txt"
    else:
        return "/home/jie/sites/money2/py/auto_invest_params.txt"
