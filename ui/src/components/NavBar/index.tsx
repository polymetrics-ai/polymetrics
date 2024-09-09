import React from 'react';
import { Link } from '@tanstack/react-router';
import { Button } from '@/components/ui/button';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { MENU_ICONS } from '@/constants/constants';

interface NavBarProps {
    onSignOut: () => void;
}

const NavBar: React.FC<NavBarProps> = ({ onSignOut }) => {
    const { routeIcons, userIcons } = MENU_ICONS;

    return (
        <aside className="w-[60px] h-full flex flex-col justify-between py-8 bg-white">
            <nav className="flex flex-col items-center space-y-6">
                <Button
                    className="mx-2 h-full bg-none hover:bg-none ring-0 focus:ring-0"
                    size="icon"
                    aria-label="Home"
                >
                    <img className="" src="pm-logo.svg" />
                </Button>
                {routeIcons.map((route, key) => (
                    <TooltipProvider delayDuration={50} key={key}>
                        <Tooltip>
                            <TooltipTrigger>
                                <Link to={route?.value ? route?.value : ''}>
                                    <Button
                                        variant="ghost"
                                        size="icon"
                                        className={`mx-2 p-0 shadow-none  bg-auto bg-transparent hover:bg-emerald-100 ${route.className ? route.className : ''}`}
                                        aria-label={route.label}
                                    >
                                        <img className="h-6 w-6" src={route.icon} />
                                    </Button>
                                </Link>
                            </TooltipTrigger>
                            <TooltipContent className="bg-emerald-600" side="right" sideOffset={5}>
                                {route.label}
                            </TooltipContent>
                        </Tooltip>
                    </TooltipProvider>
                ))}
            </nav>
            <nav className="mt-auto flex flex-col items-center space-y-6">
                {userIcons.map((user, key) => (
                    <TooltipProvider delayDuration={50} key={key}>
                        <Tooltip>
                            <TooltipTrigger>
                                <Button
                                    variant="ghost"
                                    size="icon"
                                    className={`mx-2 p-0 shadow-none bg-auto bg-transparent hover:bg-emerald-100 ${user.className ? user.className : ''}`}
                                    aria-label={user.label}
                                    onClick={
                                        user.label === 'Logout' ? () => onSignOut() : undefined
                                    }
                                >
                                    <img className="h-6 w-6" src={user.icon} />
                                </Button>
                            </TooltipTrigger>
                            <TooltipContent className="bg-emerald-600" side="right" sideOffset={5}>
                                {user.label}
                            </TooltipContent>
                        </Tooltip>
                    </TooltipProvider>
                ))}
            </nav>
        </aside>
    );
};

export default NavBar;
