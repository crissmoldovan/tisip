import pjsua2 as pj
import sys
import time

#
# Basic data structure test, to make sure basic struct
# and array operations work
#
def ua_data_test():
	#
	# AuthCredInfo
	#
	print "UA data types test.."
	the_realm = "pjsip.org"
	ci = pj.AuthCredInfo()
	ci.realm = the_realm
	ci.dataType = 20
	
	ci2 = ci
	assert ci.dataType == 20
	assert ci2.realm == the_realm
	
	#
	# UaConfig
	# See here how we manipulate std::vector
	#
	uc = pj.UaConfig()
	uc.maxCalls = 10
	uc.userAgent = "Python"
	uc.nameserver = pj.StringVector(["10.0.0.1", "10.0.0.2"])
	uc.nameserver.append("NS1")
	
	uc2 = uc
	assert uc2.maxCalls == 10
	assert uc2.userAgent == "Python"
	assert len(uc2.nameserver) == 3
	assert uc2.nameserver[0] == "10.0.0.1"
	assert uc2.nameserver[1] == "10.0.0.2"
	assert uc2.nameserver[2] == "NS1"

	print "  Dumping nameservers: ",
	for s in uc2.nameserver:
		print s,
	print ""

#
# Exception test
#
def ua_run_test_exception():
	print "Exception test.."
	ep = pj.Endpoint()
	ep.libCreate()
	got_exception = False
	try:
		ep.natDetectType()
	except pj.Error, e:
		got_exception = True
		print "  Got exception: status=%u, reason=%s,\n  title=%s,\n  srcFile=%s, srcLine=%d" % \
			(e.status, e.reason, e.title, e.srcFile, e.srcLine)
		assert e.status == 370050
		assert e.reason.find("PJNATH_ESTUNINSERVER") >= 0
		assert e.title == "pjsua_detect_nat_type()"
	assert got_exception

#
# Custom log writer
#
class MyLogWriter(pj.LogWriter):
	def write(self, entry):
		print "This is Python:", entry.msg
		
#
# Testing log writer callback
#
def ua_run_log_test():
	print "Logging test.."
	ep_cfg = pj.EpConfig()
	
	lw = MyLogWriter()
	ep_cfg.logConfig.writer = lw
	ep_cfg.logConfig.decor = ep_cfg.logConfig.decor & ~(pj.PJ_LOG_HAS_CR | pj.PJ_LOG_HAS_NEWLINE) 
	
	ep = pj.Endpoint()
	ep.libCreate()
	ep.libInit(ep_cfg)
	ep.libDestroy()
	
#
# Simple create, init, start, and destroy sequence
#
def ua_run_ua_test():
	print "UA test run.."
	ep_cfg = pj.EpConfig()
	
	ep = pj.Endpoint()
	ep.libCreate()
	ep.libInit(ep_cfg)
	ep.libStart()
	
	print "************* Endpoint started ok, now shutting down... *************"
	ep.libDestroy()

#
# Tone generator
#
def ua_tonegen_test():
        print "UA tonegen test.."
        ep_cfg = pj.EpConfig()

        ep = pj.Endpoint()
        ep.libCreate()
        ep.libInit(ep_cfg)
        ep.libStart()
        
        tonegen = pj.ToneGenerator()
        tonegen.createToneGenerator()

        tone = pj.ToneDesc()
        tone.freq1 = 400
        tone.freq2 = 600
        tone.on_msec = 1000
        tone.off_msec = 1000
        tones = pj.ToneDescVector()
        tones.append(tone)

        digit = pj.ToneDigit()
        digit.digit = '0'
        digit.on_msec = 1000
        digit.off_msec = 1000
        digits = pj.ToneDigitVector()
        digits.append(digit)

        adm = ep.audDevManager()
        spk = adm.getPlaybackDevMedia()

        tonegen.play(tones, True)
        tonegen.startTransmit(spk)
        time.sleep(5)

	tonegen.stop()
        tonegen.playDigits(digits, True)
        time.sleep(5)

	dm = tonegen.getDigitMap()
	print dm[0].digit
	dm[0].freq1 = 400
	dm[0].freq2 = 600
	tonegen.setDigitMap(dm)
	
	tonegen.stop()
        tonegen.playDigits(digits, True)
        time.sleep(5)
	
        tonegen = None

        ep.libDestroy()

#
# main()
#
if __name__ == "__main__":
	ua_data_test()
	ua_run_test_exception()
	ua_run_log_test()
	ua_run_ua_test()
	ua_tonegen_test()
	sys.exit(0)

	
