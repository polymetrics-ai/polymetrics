import { Button } from '@/components/ui/button';
function Footer() {
    return (
        <footer className="flex my-4 justify-center items-center w-full text-xs tracking-normal p-0">
            <p className="h-4.5 self-stretch my-auto text-slate-600">
                © Polymetrics. All rights reserved.
            </p>
            <Button variant="link" className="h-4.5 p-0 text-xs self-stretch my-auto">
                Terms of Use
            </Button>
            <Button variant="link" className="h-4.5 p-0 text-xs self-stretch my-auto">
                • Privacy Policy
            </Button>
        </footer>
    );
}

export default Footer;
