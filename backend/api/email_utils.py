import os
from email.mime.image import MIMEImage

from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string


def send_html_email(subject, recipient, template_name, context, text_content, logo_cid='bovion_logo'):
    base_dir = getattr(settings, 'BASE_DIR', None)
    static_logo_path = None
    if base_dir:
        static_logo_path = os.path.join(str(base_dir), 'static', 'images', 'bovion-logo.png')

    logo_url = getattr(
        settings,
        'LOGO_URL',
        'https://vcxdtkekiweomnemfwdk.supabase.co/storage/v1/object/public/imagenes/bovion-logo.png'
    )

    resolved_logo_cid = logo_cid if static_logo_path and os.path.exists(static_logo_path) else None

    html_content = render_to_string(template_name, {
        **context,
        'logo_url': logo_url,
        'logo_cid': resolved_logo_cid,
    })

    email_message = EmailMultiAlternatives(
        subject,
        text_content,
        settings.DEFAULT_FROM_EMAIL,
        [recipient],
    )
    email_message.attach_alternative(html_content, 'text/html')

    if resolved_logo_cid and static_logo_path and os.path.exists(static_logo_path):
        try:
            with open(static_logo_path, 'rb') as f:
                img_data = f.read()
            image = MIMEImage(img_data)
            image.add_header('Content-ID', f'<{resolved_logo_cid}>')
            image.add_header('Content-Disposition', 'inline')
            image.add_header('X-Attachment-Id', resolved_logo_cid)
            email_message.attach(image)
        except Exception:
            pass

    email_message.send(fail_silently=False)
