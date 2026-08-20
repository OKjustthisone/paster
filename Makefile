.PHONY: all app run clean install

all: app

app:
	@chmod +x scripts/build_app.sh
	@./scripts/build_app.sh

run: app
	@echo "🚀 正在启动 Paster..."
	@open build/Paster.app

install: app
	@echo "📦 正在安装 Paster 到 /Applications..."
	@cp -R build/Paster.app /Applications/
	@echo "✅ 安装成功！可在应用程序中找到并运行 Paster。"

clean:
	@rm -rf build .build
	@echo "🧹 清理完成。"
