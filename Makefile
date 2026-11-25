APP_NAME = "Mac Wallspace"

.PHONY: all app release run add clean

all: app

app:
	chmod +x scripts/*.sh
	./scripts/build_app.sh

release: app
	chmod +x scripts/*.sh
	./scripts/create_dmg.sh

run: app
	open "dist/$(APP_NAME).app"

add:
	@if [ -z "$(VIDEO)" ]; then \
		echo "Usage: make add VIDEO=/path/to/video.mp4"; \
		exit 1; \
	fi
	chmod +x scripts/add_wallpaper.sh
	./scripts/add_wallpaper.sh "$(VIDEO)"

clean:
	rm -rf dist/
