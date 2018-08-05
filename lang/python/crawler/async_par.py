from contextlib import contextmanager

@contextmanager
def locker():
    print('into')
    try:
        yield
    except Exception as ex:
        print('some exception:', ex)
    else:
        print('done just fine')
    finally:
        print('cleaning up')

print('----BEGIN-----')
with locker():
    print('do something')
    raise RuntimeError('killing intended')


def sub_iter():
    for i in range(10):
        yield i
    print('sub done')

def main_iter():
    print('init')
    for a in sub_iter():
        yield a * a
        print('next')
    print('done')

for a in main_iter():
    print(a)
