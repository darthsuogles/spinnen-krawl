import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', '-c', help='prepare configuration')
    args = parser.parse_args()
    print(args)
