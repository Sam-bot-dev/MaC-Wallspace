APP_NAME = "Mac Wallspace"

.PHONY: all app release run clean test

all: app

app:
	chmod +x scripts/build_app.sh
	./scripts/build_app.sh

release: app
	chmod +x scripts/create_dmg.sh
	./scripts/create_dmg.sh

run: app
	open "dist/$(APP_NAME).app"

clean:
	rm -rf dist/
