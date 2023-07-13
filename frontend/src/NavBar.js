import { useState } from "react";

export default function NavBar() {
    const [navOpen, setNavOpen] = useState(false);

    return (
        <div data-mode="dark">
            <nav className="bg-white border-gray-200 dark:bg-gray-900 fixed w-full z-20 top-0 left-0">
                <div className="max-w-screen-xl flex flex-wrap items-center justify-between mx-auto p-4">
                    <a href="/" className="flex items-center">
                        <img
                            src="https://i.imgur.com/rvMXsbm.png"
                            className="h-8 mr-3"
                            alt="Flowbite Logo"
                        />
                        <span className="self-center text-2xl font-semibold whitespace-nowrap dark:text-white">
                            OpenVPN
                        </span>
                    </a>
                    <button
                        data-collapse-toggle="navbar-default"
                        type="button"
                        className="inline-flex items-center p-2 w-10 h-10 justify-center text-sm text-gray-500 rounded-lg lg:hidden hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200 dark:text-gray-400 dark:hover:bg-gray-700 dark:focus:ring-gray-600"
                        aria-controls="navbar-default"
                        aria-expanded="false"
                        onClick={() => setNavOpen(!navOpen)}
                    >
                        <span className="sr-only">Open main menu</span>
                        <svg
                            className="w-5 h-5"
                            aria-hidden="true"
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 17 14"
                        >
                            <path
                                stroke="currentColor"
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeWidth={2}
                                d="M1 1h15M1 7h15M1 13h15"
                            />
                        </svg>
                    </button>
                    <div className={"w-full lg:block lg:w-auto" + (navOpen ? "" : " hidden")} id="navbar-default">
                        <ul className="font-medium flex flex-col p-4 lg:p-0 mt-4 border border-gray-100 rounded-lg bg-gray-50 lg:flex-row lg:space-x-8 lg:mt-0 lg:border-0 lg:bg-white dark:bg-gray-800 lg:dark:bg-gray-900 dark:border-gray-700">
                            <li>
                                <a
                                    href="https://openvpn.net/downloads/openvpn-connect-v3-windows.msi"
                                    className="block py-2 pl-3 pr-4 text-gray-900 rounded hover:bg-gray-100 lg:hover:bg-transparent lg:border-0 lg:hover:text-blue-700 lg:p-0 dark:text-white lg:dark:hover:text-blue-500 dark:hover:bg-gray-700 dark:hover:text-white lg:dark:hover:bg-transparent"
                                >
                                    Windows Client
                                </a>
                            </li>
                            <li>
                                <a
                                    href="https://openvpn.net/downloads/openvpn-connect-v3-macos.dmg"
                                    className="block py-2 pl-3 pr-4 text-gray-900 rounded hover:bg-gray-100 lg:hover:bg-transparent lg:border-0 lg:hover:text-blue-700 lg:p-0 dark:text-white lg:dark:hover:text-blue-500 dark:hover:bg-gray-700 dark:hover:text-white lg:dark:hover:bg-transparent"
                                >
                                    MacOS Client
                                </a>
                            </li>
                            <li>
                                <a
                                    href="https://openvpn.net/cloud-docs/owner/connectors/connector-user-guides/openvpn-3-client-for-linux.html"
                                    className="block py-2 pl-3 pr-4 text-gray-900 rounded hover:bg-gray-100 lg:hover:bg-transparent lg:border-0 lg:hover:text-blue-700 lg:p-0 dark:text-white lg:dark:hover:text-blue-500 dark:hover:bg-gray-700 dark:hover:text-white lg:dark:hover:bg-transparent"
                                >
                                    Linux Client
                                </a>
                            </li>
                            <li>
                                <a
                                    href="https://play.google.com/store/apps/details?id=net.openvpn.openvpn"
                                    className="block py-2 pl-3 pr-4 text-gray-900 rounded hover:bg-gray-100 lg:hover:bg-transparent lg:border-0 lg:hover:text-blue-700 lg:p-0 dark:text-white lg:dark:hover:text-blue-500 dark:hover:bg-gray-700 dark:hover:text-white lg:dark:hover:bg-transparent"
                                >
                                    Android Client
                                </a>
                            </li>
                            <li>
                                <a
                                    href="https://apps.apple.com/us/app/openvpn-connect/id590379981"
                                    className="block py-2 pl-3 pr-4 text-gray-900 rounded hover:bg-gray-100 lg:hover:bg-transparent lg:border-0 lg:hover:text-blue-700 lg:p-0 dark:text-white lg:dark:hover:text-blue-500 dark:hover:bg-gray-700 dark:hover:text-white lg:dark:hover:bg-transparent"
                                >
                                    iOS Client
                                </a>
                            </li>
                        </ul>
                    </div>
                </div>
            </nav>
        </div>
    );
}