import os
import re

def patch_manifest():
    manifest_paths = ['android/app/src/main/AndroidManifest.xml']
    queries_block = """    <queries>
        <package android:name="com.whatsapp" />
        <package android:name="com.whatsapp.w4b" />
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="upi" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="sms" />
        </intent>
        <intent>
            <action android:name="android.intent.action.SENDTO" />
            <data android:scheme="smsto" />
        </intent>
        <intent>
            <action android:name="android.intent.action.DIAL" />
            <data android:scheme="tel" />
        </intent>
    </queries>
</manifest>"""

    for path in manifest_paths:
        if os.path.exists(path):
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()

            if 'android.permission.INTERNET' not in content:
                content = content.replace('<application', '<uses-permission android:name="android.permission.INTERNET"/>\n    <application')
            if '<queries>' not in content and '</manifest>' in content:
                content = content.replace('</manifest>', queries_block)

            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Patched AndroidManifest at {path}")

if __name__ == '__main__':
    patch_manifest()
