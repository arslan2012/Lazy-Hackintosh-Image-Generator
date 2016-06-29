cd $(dirname "$0")
read -p "Generate zip(default) or installler?(z/i)(press enter for default option)" installer
xcodebuild archive -scheme LazyHackintoshGenerator -archivePath product
case "$installer" in
	"z"|"Z"|"")
		xcodebuild -exportArchive -archivePath product.xcarchive -exportFormat app -exportPath ./LazyHackintoshGenerator
		zip -r LazyHackintoshGenerator.app.zip LazyHackintoshGenerator.app
		rm -rf LazyHackintoshGenerator.app
		zip -d LazyHackintoshGenerator.app.zip __MACOSX/\*
		zip -d LazyHackintoshGenerator.app.zip \*/.DS_Store ;;
	"i"|"I")
		xcodebuild -exportArchive -archivePath product.xcarchive -exportPath ./LazyHackintoshGenerator ;;
esac
rm -rf product.xcarchive